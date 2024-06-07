# coding: utf-8
require "sam"
require "colorize"
require "../utils/utils.cr"

namespace "platform" do
  desc "The CNF test suite checks to see if the CNFs are resilient to failures."
  task "resilience", ["worker_reboot_recovery"] do |t, args|
    Log.for("verbose").info { "resilience" } if check_verbose(args)
    Log.for("verbose").debug { "resilience args.raw: #{args.raw}" } if check_verbose(args)
    Log.for("verbose").debug { "resilience args.named: #{args.named}" } if check_verbose(args)
    stdout_score("platform:resilience")
  end

  desc "Does the Platform recover the node and reschedule pods when a worker node fails"
  task "worker_reboot_recovery" do |t, args|
    task_response = CNFManager::Task.task_runner(args, task: t, check_cnf_installed: false) do |args|
      unless check_destructive(args)
        next CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Skipped, "Node not in destructive mode")
      end
      Log.info { "Running POC in destructive mode!" }
      current_dir = FileUtils.pwd
      helm = Helm::BinarySingleton.helm

      #Select the first node that isn't a master and is also schedulable
      worker_nodes = KubectlClient::Get.worker_nodes
      worker_node = worker_nodes[0]

      File.write("node_failure_values.yml", NODE_FAILED_VALUES)
      install_coredns = Helm.install("node-failure -f ./node_failure_values.yml --set nodeSelector.\"kubernetes\\.io/hostname\"=#{worker_node} stable/coredns")
      KubectlClient::Get.wait_for_install("node-failure-coredns")

      File.write("reboot_daemon_pod.yml", REBOOT_DAEMON)
      KubectlClient::Apply.file("reboot_daemon_pod.yml")
      KubectlClient::Get.wait_for_install("node-failure-coredns")

      begin

        execution_complete = repeat_with_timeout(timeout: POD_READINESS_TIMEOUT, errormsg: "Pod daemon installation has timed-out") do
          pod_ready = KubectlClient::Get.pod_status("reboot", "--field-selector spec.nodeName=#{worker_node}").split(",")[2] == "true"
          Log.info { "Waiting for reboot daemon to be ready. Current status: #{pod_ready}" }
          pod_ready
        end

        if !execution_complete
          next CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Failed to install reboot daemon")
        end

        # Find Reboot Daemon name
        reboot_daemon_pod = KubectlClient::Get.pod_status("reboot", "--field-selector spec.nodeName=#{worker_node}").split(",")[0]
        start_reboot = KubectlClient.exec("#{reboot_daemon_pod} touch /tmp/reboot")

        #Watch for Node Failure.
        execution_complete = repeat_with_timeout(timeout: GENERIC_OPERATION_TIMEOUT, errormsg: "Node shut-off has timed-out") do
          pod_ready = KubectlClient::Get.pod_status("node-failure").split(",")[2] == "true"
          node_ready = KubectlClient::Get.node_status("#{worker_node}") == "True"
          Log.info { "Waiting for Node to go offline..." }
          Log.info { "Pod Ready Status: #{pod_ready}" }
          Log.info { "Node Ready Status: #{node_ready}" }
          !pod_ready || !node_ready
        end

        if !execution_complete
          next CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Node failed to go offline")
        end

        #Watch for Node to come back online
        execution_complete = repeat_with_timeout(timeout: NODE_READINESS_TIMEOUT, errormsg: "Node startup has timed-out") do
          pod_ready = KubectlClient::Get.pod_status("node-failure", "").split(",")[2] == "true"
          node_ready = KubectlClient::Get.node_status("#{worker_node}") == "True"
          Log.info { "Waiting for Node to come back online..." }
          Log.info { "Pod Ready Status: #{pod_ready}" }
          Log.info { "Node Ready Status: #{node_ready}" }
          pod_ready && node_ready
        end

        if !execution_complete
          next CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Node failed to come back online")
        end
        
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "Node came back online")
      ensure
        Log.info { "node_failure cleanup" }
        delete_reboot_daemon = KubectlClient::Delete.file("reboot_daemon_pod.yml")
        delete_coredns = Helm.delete("node-failure")
        File.delete("reboot_daemon_pod.yml")
        File.delete("node_failure_values.yml")
      end
    end
  end
end
