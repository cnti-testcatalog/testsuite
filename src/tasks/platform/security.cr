# coding: utf-8
require "sam"
require "colorize"
require "../utils/utils.cr"

namespace "platform" do
  desc "The CNF test suite checks to see if the platform is hardened."
  task "security", ["control_plane_hardening", "cluster_admin", "exposed_dashboard", "helm_tiller"] do |t, args|
    Log.for("verbose").info { "security" } if check_verbose(args)
    stdout_score("platform:security")
  end

  desc "Is the platform control plane hardened"
  task "control_plane_hardening", ["kubescape_scan"] do |t, args|
    task_response = CNFManager::Task.task_runner(args, task: t, check_cnf_installed: false) do |args|
      results_json = Kubescape.parse
      test_json = Kubescape.test_by_test_name(results_json, "Control plane hardening")
      test_report = Kubescape.parse_test_report(test_json)

      if test_report.failed_resources.size == 0
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "Control plane hardened")
      else
        test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
        stdout_failure("Remediation: #{test_report.remediation}")
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Control plane not hardened")
      end
    end
  end

  desc "Attackers who have Cluster-admin permissions (can perform any action on any resource), can take advantage of their high privileges for malicious intentions. Determines which subjects have cluster admin permissions."
  task "cluster_admin", ["kubescape_scan"] do |t, args|
    next if args.named["offline"]?
    CNFManager::Task.task_runner(args, task: t, check_cnf_installed: false) do |args, config|
      results_json = Kubescape.parse
      test_json = Kubescape.test_by_test_name(results_json, "Cluster-admin binding")
      test_report = Kubescape.parse_test_report(test_json)

      if test_report.failed_resources.size == 0
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "No users with cluster admin role found")
      else
        test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
        stdout_failure("Remediation: #{test_report.remediation}")
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Users with cluster admin role found")
      end
    end
  end

  desc "Check if the cluster has an exposed dashboard"
  task "exposed_dashboard", ["kubescape_scan"] do |t, args|
    next if args.named["offline"]?

    CNFManager::Task.task_runner(args, task: t, check_cnf_installed: false) do |args, config|
      results_json = Kubescape.parse
      test_json = Kubescape.test_by_test_name(results_json, "Exposed dashboard")
      test_report = Kubescape.parse_test_report(test_json)

      if test_report.failed_resources.size == 0
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "No exposed dashboard found in the cluster")
      else
        test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
        stdout_failure("Remediation: #{test_report.remediation}")
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Found exposed dashboard in the cluster")
      end
    end
  end

  desc "Check if the CNF is running containers with name tiller in their image name?"
  task "helm_tiller" do |t, args|
    Kyverno.install
    CNFManager::Task.task_runner(args, task: t, check_cnf_installed: false) do |args, config|
      policy_path = Kyverno.best_practice_policy("disallow_helm_tiller/disallow_helm_tiller.yaml")
      failures = Kyverno::PolicyAudit.run(policy_path, EXCLUDE_NAMESPACES)

      if failures.size == 0
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "No Helm Tiller containers are running")
      else
        failures.each do |failure|
          failure.resources.each do |resource|
            puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
          end
        end
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Containers with the Helm Tiller image are running")
      end
    end
  end

  desc "Kubescape secret/etcd"
  task "kubescape_secret_etcd", ["kubescape_scan"] do |t, args|
    next if args.named["offline"]?

    CNFManager::Task.task_runner(args, task: t, check_cnf_installed: false) do |args, config|
      results_json = Kubescape.parse
      test_json = Kubescape.test_by_test_name(results_json, "Secret/ETCD encryption enabled")
      test_report = Kubescape.parse_test_report(test_json)

      if test_report.failed_resources.size == 0
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "Secret/etcd encryption enabled")
      else
        test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
        stdout_failure("Remediation: #{test_report.remediation}")
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Secret/etcd encryption disabled")
      end
    end
  end
end
