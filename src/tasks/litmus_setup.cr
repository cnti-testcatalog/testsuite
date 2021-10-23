# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Install LitmusChaos"
task "install_litmus" do |_, args|
  if args.named["offline"]?
    Log.info {"install litmus offline mode"}
    AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/litmus-operator-v#{LitmusManager::Version}.yaml")
    KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/litmus-operator-v#{LitmusManager::Version}.yaml")
    KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/chaos_crds.yaml")
  else
    KubectlClient::Apply.file("https://litmuschaos.github.io/litmus/litmus-operator-v#{LitmusManager::Version}.yaml")
    KubectlClient::Apply.file("https://raw.githubusercontent.com/litmuschaos/chaos-operator/master/deploy/chaos_crds.yaml")
  end
end

module LitmusManager

  Version = "2.1.0"

  def self.cordon_target_node(deployment_label, deployment_value)
    app_nodeName_cmd = "kubectl get pods -l #{deployment_label}=#{deployment_value} -o=jsonpath='{.items[0].spec.nodeName}'"
    Log.info { "Getting the operator node name: #{app_nodeName_cmd}" }
    status_code = Process.run("#{app_nodeName_cmd}", shell: true, output: appNodeName_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status
    Log.for("verbose").info { "status_code: #{status_code}" } 
    app_nodeName = appNodeName_response.to_s 
    status_code = KubectlClient::Cordon.command("#{app_nodeName}")
    Log.for("verbose").info { "status_code: #{status_code}" }
    Log.info { "The target node has been cordoned sucessfully" }
  end

  ## wait_for_test will wait for the completion of litmus test
  def self.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args)
    ## Maximum wait time is TCD (total chaos duration) + 60s (additional wait time)
    delay=2
    timeout="#{total_chaos_duration}".to_i + 60
    retry=timeout/delay
    chaos_result_name = "#{test_name}-#{chaos_experiment_name}"
    wait_count = 0
    status_code = -1
    experimentStatus = ""
    
    experimentStatus_cmd = "kubectl get chaosengine.litmuschaos.io #{test_name} -o jsonpath='{.status.engineStatus}'"
    puts "Checking experiment status  #{experimentStatus_cmd}" if check_verbose(args)

    ## Wait for completion of chaosengine which indicates the completion of chaos
    until (status_code == 0 && experimentStatus == "Completed") || wait_count >= retry
      sleep delay
      experimentStatus_cmd = "kubectl get chaosengine.litmuschaos.io #{test_name} -o jsonpath='{.status.experiments[0].status}'"
      puts "Checking experiment status  #{experimentStatus_cmd}" if check_verbose(args)
      status_code = Process.run("#{experimentStatus_cmd}", shell: true, output: experimentStatus_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status
      puts "status_code: #{status_code}" if check_verbose(args)
      puts "Checking experiment status  #{experimentStatus_cmd}" if check_verbose(args)
      experimentStatus = experimentStatus_response.to_s
      Log.info {"#{chaos_experiment_name} experiment status: "+experimentStatus}

      emoji_test_failed= "🗡️💀♻️"
      Log.info { "experimentStatus #{experimentStatus}"}
      if (experimentStatus != "Waiting for Job Creation" && experimentStatus != "Running" && experimentStatus != "Completed")
        Log.info {"#{test_name}: wait_for_test failed."}
      end
      wait_count = wait_count + 1
    end

    verdict = ""
    wait_count = 0
    verdict_cmd = "kubectl get chaosresults.litmuschaos.io #{chaos_result_name} -o jsonpath='{.status.experimentStatus.verdict}'"
    puts "Checking experiment verdict  #{verdict_cmd}" if check_verbose(args)
    ## Check the chaosresult verdict
    until (status_code == 0 && verdict != "Awaited") || wait_count >= 30
      sleep delay
      status_code = Process.run("#{verdict_cmd}", shell: true, output: verdict_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status
      puts "status_code: #{status_code}" if check_verbose(args)
      puts "verdict: #{verdict_response.to_s}"  if check_verbose(args)
      verdict = verdict_response.to_s
      wait_count = wait_count + 1
    end
  end

  ## check_chaos_verdict will check the verdict of chaosexperiment
  def self.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args): Bool
    verdict_cmd = "kubectl get chaosresults.litmuschaos.io #{chaos_result_name} -o jsonpath='{.status.experimentStatus.verdict}'"
    puts "Checking experiment verdict  #{verdict_cmd}" if check_verbose(args)
    status_code = Process.run("#{verdict_cmd}", shell: true, output: verdict_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status
    puts "status_code: #{status_code}" if check_verbose(args)
    puts "verdict: #{verdict_response.to_s}"  if check_verbose(args)
    verdict = verdict_response.to_s

    emoji_test_failed= "🗡️💀♻️"
    if verdict == "Pass"
      return true
    else
      Log.info {"#{chaos_experiment_name} chaos test failed: #{chaos_result_name}, verdict: #{verdict}"}
      puts "#{chaos_experiment_name} chaos test failed #{emoji_test_failed}"
      return false
    end
  end

  ## install_litmus will install the infra components of litmus
  def self.install_litmus(args)
    if args.named["offline"]?
      Log.info {"install litmus offline mode"}
      AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/litmus-operator-v#{LitmusManager::Version}.yaml")
      KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/litmus-operator-v#{LitmusManager::Version}.yaml")
      KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/chaos_crds.yaml")
    else
      KubectlClient::Apply.file("https://litmuschaos.github.io/litmus/litmus-operator-v#{LitmusManager::Version}.yaml")
      KubectlClient::Apply.file("https://raw.githubusercontent.com/litmuschaos/chaos-operator/master/deploy/chaos_crds.yaml")
    end
  end

  ## cordon_target_node will cordon the target node under chaos
  def self.cordon_target_node(args)
    CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "cordon_target_node" } if check_verbose(args)
    Log.debug { "cnf_config: #{config}" }
    #TODO tests should fail if cnf not installed
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
    Log.info { "Current Resource Name: #{resource["name"]} Type: #{resource["kind"]}" }
    deployment_label="#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}"
    deployment_label_value="#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}"

    app_nodeName_cmd = "kubectl get pods -l #{ deployment_label}=#{ deployment_label_value } -o=jsonpath='{.items[0].spec.nodeName}'"
    puts "Getting the operator node name #{app_nodeName_cmd}" if check_verbose(args)
    status_code = Process.run("#{app_nodeName_cmd}", shell: true, output: appNodeName_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status
    puts "status_code: #{status_code}" if check_verbose(args)  
    app_nodeName = appNodeName_response.to_s 
    status_code = KubectlClient::Cordon.command("#{app_nodeName}")
    puts "status_code: #{status_code}" if check_verbose(args) 
    end
    if task_response
      resp = upsert_passed_task("cordon_target_node","✔️  PASSED: The target node is cordoned sucessfully 🗡️💀♻️")
    else
      resp = upsert_failed_task("cordon_target_node","✖️  FAILED: The target node is unable to cordoned sucessfully 🗡️💀♻️")
    end  
  end
end
end