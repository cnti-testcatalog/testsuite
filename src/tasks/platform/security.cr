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
    task_response = CNFManager::Task.task_runner(args) do |args|

    VERBOSE_LOGGING.info "control_plane_hardening" if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Control plane hardening")

    emoji_security="🔓🔑"
    if Kubescape.test_passed?(test_json) 
      upsert_passed_task("control_plane_hardening", "✔️  PASSED: Control plane hardened #{emoji_security}")
    else
      resp = upsert_failed_task("control_plane_hardening", "✖️  FAILED: Control plane not hardened #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
      resp
    end
    end
  end

  desc "Attackers who have Cluster-admin permissions (can perform any action on any resource), can take advantage of their high privileges for malicious intentions. Determines which subjects have cluster admin permissions."
  task "cluster_admin", ["kubescape_scan"] do |_, args|
    unless args.named["offline"]?
        CNFManager::Task.task_runner(args) do |args, config|
      VERBOSE_LOGGING.info "cluster_admin" if check_verbose(args)
      results_json = Kubescape.parse
      test_json = Kubescape.test_by_test_name(results_json, "Cluster-admin binding")

      emoji_security="🔓🔑"
      if Kubescape.test_passed?(test_json) 
        upsert_passed_task("cluster_admin", "✔️  PASSED: No users with cluster admin role found #{emoji_security}")
      else
        resp = upsert_failed_task("cluster_admin", "✖️  FAILED: Users with cluster admin role found #{emoji_security}")
        Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
        puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
        resp
      end
    end
    end
  end

  desc "Check if the cluster has an exposed dashboard"
  task "exposed_dashboard", ["kubescape_scan"] do |_, args|
    next if args.named["offline"]?

    CNFManager::Task.task_runner(args) do |args, config|
      Log.for("verbose").info { "exposed_dashboard" } if check_verbose(args)
      results_json = Kubescape.parse
      test_json = Kubescape.test_by_test_name(results_json, "Exposed dashboard")

      emoji_security = "🔓🔑"
      if Kubescape.test_passed?(test_json)
        upsert_passed_task("exposed_dashboard", "✔️  PASSED: No exposed dashboard found in the cluster #{emoji_security}")
      else
        resp = upsert_failed_task("exposed_dashboard", "✖️  FAILED: Found exposed dashboard in the cluster #{emoji_security}")
        Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
        puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
        resp
      end
    end
  end

  desc "Check if the CNF is running containers with name tiller in their image name?"
  task "helm_tiller" do |_, args|
    Log.for("verbose").info { "platform:helm_tiller" }
    Kyverno.install

    CNFManager::Task.task_runner(args) do |args, config|
      policy_path = Kyverno.best_practice_policy("disallow_helm_tiller/disallow_helm_tiller.yaml")
      apply_result = KubectlClient::Apply.file(policy_path)
      sleep(3.seconds)
      emoji_passed="🏷️      ✔️"
      emoji_failed="🏷️      ❌"
      failures = Kyverno::PolicyReport.failures("disallow-helm-tiller")

      if failures.size == 0
        resp = upsert_passed_task("helm_tiller", "✔️  PASSED: No Helm Tiller containers are running #{emoji_passed}")
      else
        resp = upsert_failed_task("helm_tiller", "✖️  FAILED: Containers with the Helm Tiller image are running #{emoji_failed}")
        failures.each do |failure|
          failure.resources.each do |resource|
            puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
          end
        end
      end
    end
  ensure
    Kyverno::ClusterPolicy.delete_all()
    Kyverno::PolicyReport.delete_all()
  end
end
