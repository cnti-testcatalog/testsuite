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
  task "control_plane_hardening", ["kubescape_scan"] do |_, args|
    task_response = CNFManager::Task.task_runner(args, check_cnf_installed: false) do |args|
      task_start_time = Time.utc
      testsuite_task = "control_plane_hardening"
      Log.for(testsuite_task).info { "Starting test" }

      results_json = Kubescape.parse
      test_json = Kubescape.test_by_test_name(results_json, "Control plane hardening")
      test_report = Kubescape.parse_test_report(test_json)

      emoji_security="🔓🔑"
      if test_report.failed_resources.size == 0
        upsert_passed_task(testsuite_task, "✔️  PASSED: Control plane hardened #{emoji_security}", task_start_time)
      else
        resp = upsert_failed_task(testsuite_task, "✖️  FAILED: Control plane not hardened #{emoji_security}", task_start_time)
        test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
        stdout_failure("Remediation: #{test_report.remediation}")
        resp
      end
    end
  end

  desc "Attackers who have Cluster-admin permissions (can perform any action on any resource), can take advantage of their high privileges for malicious intentions. Determines which subjects have cluster admin permissions."
  task "cluster_admin", ["kubescape_scan"] do |_, args|
    next if args.named["offline"]?
    CNFManager::Task.task_runner(args, check_cnf_installed: false) do |args, config|
      task_start_time = Time.utc
      testsuite_task = "cluster_admin"
      Log.for(testsuite_task).info { "Starting test" }

      results_json = Kubescape.parse
      test_json = Kubescape.test_by_test_name(results_json, "Cluster-admin binding")
      test_report = Kubescape.parse_test_report(test_json)

      emoji_security="🔓🔑"
      if test_report.failed_resources.size == 0
        upsert_passed_task(testsuite_task, "✔️  PASSED: No users with cluster admin role found #{emoji_security}", task_start_time)
      else
        resp = upsert_failed_task(testsuite_task, "✖️  FAILED: Users with cluster admin role found #{emoji_security}", task_start_time)
        test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
        stdout_failure("Remediation: #{test_report.remediation}")
        resp
      end
    end
  end

  desc "Check if the cluster has an exposed dashboard"
  task "exposed_dashboard", ["kubescape_scan"] do |_, args|
    next if args.named["offline"]?

    CNFManager::Task.task_runner(args, check_cnf_installed: false) do |args, config|
      task_start_time = Time.utc
      testsuite_task = "exposed_dashboard"
      Log.for(testsuite_task).info { "Starting test" }

      results_json = Kubescape.parse
      test_json = Kubescape.test_by_test_name(results_json, "Exposed dashboard")
      test_report = Kubescape.parse_test_report(test_json)

      emoji_security = "🔓🔑"
      if test_report.failed_resources.size == 0
        upsert_passed_task(testsuite_task, "✔️  PASSED: No exposed dashboard found in the cluster #{emoji_security}", task_start_time)
      else
        resp = upsert_failed_task(testsuite_task, "✖️  FAILED: Found exposed dashboard in the cluster #{emoji_security}", task_start_time)
        test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
        stdout_failure("Remediation: #{test_report.remediation}")
        resp
      end
    end
  end

  desc "Check if the CNF is running containers with name tiller in their image name?"
  task "helm_tiller" do |_, args|
    emoji_security="🔓🔑"
    task_start_time = Time.utc
    testsuite_task = "helm_tiller"
    Log.for(testsuite_task).info { "Starting test" }

    Kyverno.install

    CNFManager::Task.task_runner(args, check_cnf_installed: false) do |args, config|
      policy_path = Kyverno.best_practice_policy("disallow_helm_tiller/disallow_helm_tiller.yaml")
      failures = Kyverno::PolicyAudit.run(policy_path, EXCLUDE_NAMESPACES)

      if failures.size == 0
        resp = upsert_passed_task(testsuite_task, "✔️  PASSED: No Helm Tiller containers are running #{emoji_security}", task_start_time)
      else
        resp = upsert_failed_task(testsuite_task, "✖️  FAILED: Containers with the Helm Tiller image are running #{emoji_security}", task_start_time)
        failures.each do |failure|
          failure.resources.each do |resource|
            puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
          end
        end
      end
    end
  end
end
