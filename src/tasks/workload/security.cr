# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "CNF containers should be isolated from one another and the host.  The CNF Test suite uses tools like Falco, Sysdig Inspect and gVisor"
task "security", [
    "privileged",
    "non_root_user",
    "symlink_file_system",
    "privilege_escalation",
    "insecure_capabilities",
    "resource_policies",
    "linux_hardening",
    "ingress_egress_blocked",
    "host_pid_ipc_privileges",
    "non_root_containers",
    "privileged_containers",
    "immutable_file_systems",
    "hostpath_mounts",
    "container_sock_mounts",
    "external_ips",
    "selinux_options",
    "sysctls",
    "host_network",
    "service_account_mapping",
    "application_credentials"
  ] do |_, args|
  stdout_score("security")
  case "#{ARGV.join(" ")}" 
  when /security/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end

desc "Check if pods in the CNF use sysctls with restricted values"
task "sysctls" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "sysctls" }
    Kyverno.install

    emoji_security = "🔓🔑"
    policy_path = Kyverno.policy_path("pod-security/baseline/restrict-sysctls/restrict-sysctls.yaml")
    failures = Kyverno::PolicyAudit.run(policy_path, EXCLUDE_NAMESPACES)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    failures = Kyverno.filter_failures_for_cnf_resources(resource_keys, failures)

    if failures.size == 0
      resp = upsert_passed_task("sysctls", "✔️  PASSED: No restricted values found for sysctls #{emoji_security}")
    else
      resp = upsert_failed_task("sysctls", "✖️  FAILED: Restricted values for are being used for sysctls #{emoji_security}")
      failures.each do |failure|
        failure.resources.each do |resource|
          puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
        end
      end
    end
  end
end

desc "Check if the CNF has services with external IPs configured"
task "external_ips" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "external_ips" }
    Kyverno.install
    emoji_security = "🔓🔑"
    policy_path = Kyverno.best_practice_policy("restrict-service-external-ips/restrict-service-external-ips.yaml")
    failures = Kyverno::PolicyAudit.run(policy_path, EXCLUDE_NAMESPACES)

    resource_keys = CNFManager.workload_resource_keys(args, config)
    failures = Kyverno.filter_failures_for_cnf_resources(resource_keys, failures)
    
    if failures.size == 0
      resp = upsert_passed_task("external_ips", "✔️  PASSED: Services are not using external IPs #{emoji_security}")
    else
      resp = upsert_failed_task("external_ips", "✖️  FAILED: Services are using external IPs #{emoji_security}")
      failures.each do |failure|
        failure.resources.each do |resource|
          puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
        end
      end
    end
  end
end

desc "Check if the CNF or the cluster resources have custom SELinux options"
task "selinux_options" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "selinux_options" }
    Kyverno.install

    emoji_security = "🔓🔑"
    check_policy_path = Kyverno::CustomPolicies::SELinuxEnabled.new.policy_path
    check_failures = Kyverno::PolicyAudit.run(check_policy_path, EXCLUDE_NAMESPACES)

    disallow_policy_path = Kyverno.policy_path("pod-security/baseline/disallow-selinux/disallow-selinux.yaml")
    disallow_failures = Kyverno::PolicyAudit.run(disallow_policy_path, EXCLUDE_NAMESPACES)

    #TODO check for AppArmor as well, and the cnf should have either selinux or apparmor
    # IF SELinux is not enabled, skip this test
    # Else check for SELinux options

    resource_keys = CNFManager.workload_resource_keys(args, config)
    check_failures = Kyverno.filter_failures_for_cnf_resources(resource_keys, check_failures)

    if check_failures.size == 0
      # upsert_skipped_task("selinux_options", "⏭️  🏆 SKIPPED: Pods are not using SELinux options #{emoji_security}")
      upsert_na_task("selinux_options", "⏭️  🏆 N/A: Pods are not using SELinux #{emoji_security}")
    else
      failures = Kyverno.filter_failures_for_cnf_resources(resource_keys, disallow_failures)

      if failures.size == 0
        resp = upsert_passed_task("selinux_options", "✔️  🏆 PASSED: Pods are not using custom SELinux options that can be used for privilege escalations #{emoji_security}")
      else
        resp = upsert_failed_task("selinux_options", "✖️  🏆 FAILED: Pods are using custom SELinux options that can be used for privilege escalations #{emoji_security}")
        failures.each do |failure|
          failure.resources.each do |resource|
            puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
          end
        end
      end

    end

  end
end

desc "Check if the CNF is running containers with container sock mounts"
task "container_sock_mounts" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "container_sock_mounts" }
    Kyverno.install
    emoji_security = "🔓🔑"
    policy_path = Kyverno.best_practice_policy("disallow_cri_sock_mount/disallow_cri_sock_mount.yaml")
    failures = Kyverno::PolicyAudit.run(policy_path, EXCLUDE_NAMESPACES)

    if failures.size == 0
      resp = upsert_passed_task("container_sock_mounts", "✔️  🏆 PASSED: Container engine daemon sockets are not mounted as volumes #{emoji_security}")
    else
      resp = upsert_failed_task("container_sock_mounts", "✖️  🏆 FAILED: Container engine daemon sockets are mounted as volumes #{emoji_security}")
      failures.each do |failure|
        failure.resources.each do |resource|
          puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
        end
      end
    end
  end
end

desc "Check if any containers are running in as root"
task "non_root_user" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "non_root_user" }
    Kyverno.install

    emoji_security = "🔓🔑"
    policy_path = Kyverno.policy_path("pod-security/restricted/require-run-as-non-root-user/require-run-as-non-root-user.yaml")
    policy_failures = Kyverno::PolicyAudit.run(policy_path, EXCLUDE_NAMESPACES)

    resource_keys = CNFManager.workload_resource_keys(args, config)
    failures = Kyverno.filter_failures_for_cnf_resources(resource_keys, policy_failures)

    if check_failures.size == 0
      resp = upsert_passed_task("non_root_user", "✔️  🏆 PASSED: No pods using root user #{emoji_security}")
    else
      resp = upsert_failed_task("non_root_user", "✖️  🏆 FAILED: Found pods using root user #{emoji_security}")
      failures.each do |failure|
        failure.resources.each do |resource|
          puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
        end
      end
    end

  end
     if task_response
       upsert_passed_task("non_root_user", "✔️  PASSED: Root user not found #{emoji_no_root}")
     else
       upsert_failed_task("non_root_user", "✖️  FAILED: Root user found #{emoji_root}")
     end
   end
end

desc "Check if any containers are running in privileged mode"
task "privileged" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "privileged" } if check_verbose(args)
    white_list_container_names = config.cnf_config[:white_list_container_names]
    VERBOSE_LOGGING.info "white_list_container_names #{white_list_container_names.inspect}" if check_verbose(args)
    violation_list = [] of NamedTuple(kind: String, name: String, container: String, namespace: String)
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|

      privileged_list = KubectlClient::Get.privileged_containers
      white_list_containers = ((PRIVILEGED_WHITELIST_CONTAINERS + white_list_container_names) - [container])
      # Only check the containers that are in the deployed helm chart or manifest
      (privileged_list & ([container.as_h["name"].as_s] - white_list_containers)).each do |container_name|
        violation_list << {kind: resource[:kind], name: resource[:name], container: container_name, namespace: resource[:namespace]}
      end
      if violation_list.size > 0
        false
      else
        true
      end
    end
    LOGGING.debug "violator list: #{violation_list.flatten}"
    emoji_security="🔓🔑"
    if task_response 
      upsert_passed_task("privileged", "✔️  PASSED: No privileged containers #{emoji_security}")
    else
      upsert_failed_task("privileged", "✖️  FAILED: Found #{violation_list.size} privileged containers #{emoji_security}")
      violation_list.each do |violation|
        stdout_failure("Privileged container #{violation[:container]} in #{violation[:kind]}/#{violation[:name]} in the #{violation[:namespace]} namespace")
      end
    end
  end
end

desc "Check if any containers are running in privileged mode"
task "privilege_escalation", ["kubescape_scan"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "privilege_escalation" if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Allow privilege escalation")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security="🔓🔑"
    if test_report.failed_resources.size == 0 
      upsert_passed_task("privilege_escalation", "✔️  PASSED: No containers that allow privilege escalation were found #{emoji_security}")
    else
      resp = upsert_failed_task("privilege_escalation", "✖️  FAILED: Found containers that allow privilege escalation #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Check if an attacker can use symlink for arbitrary host file system access."
task "symlink_file_system", ["kubescape_scan"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "symlink_file_system" if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "CVE-2021-25741 - Using symlink for arbitrary host file system access.")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security="🔓🔑"
    if test_report.failed_resources.size == 0
      upsert_passed_task("symlink_file_system", "✔️  PASSED: No containers allow a symlink attack #{emoji_security}")
    else
      resp = upsert_failed_task("symlink_file_system", "✖️  FAILED: Found containers that allow a symlink attack #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Check if applications credentials are in configuration files."
task "application_credentials", ["kubescape_scan"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "application_credentials" if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Applications credentials in configuration files")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security="🔓🔑"
    if test_report.failed_resources.size == 0
      upsert_passed_task("application_credentials", "✔️  PASSED: No applications credentials in configuration files #{emoji_security}")
    else
      resp = upsert_failed_task("application_credentials", "✖️  FAILED: Found applications credentials in configuration files #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Check if potential attackers may gain access to a POD and inherit access to the entire host network. For example, in AWS case, they will have access to the entire VPC."
task "host_network", ["kubescape_scan"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "host_network" if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "HostNetwork access")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security="🔓🔑"
    if test_report.failed_resources.size == 0
      upsert_passed_task("host_network", "✔️  PASSED: No host network attached to pod #{emoji_security}")
    else
      resp = upsert_failed_task("host_network", "✖️  FAILED: Found host network attached to pod #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Potential attacker may gain access to a POD and steal its service account token. Therefore, it is recommended to disable automatic mapping of the service account tokens in service account configuration and enable it only for PODs that need to use them."
task "service_account_mapping", ["kubescape_scan"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "service_account_mapping" if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Automatic mapping of service account")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security="🔓🔑"
    if test_report.failed_resources.size == 0 
      upsert_passed_task("service_account_mapping", "✔️  PASSED: No service accounts automatically mapped #{emoji_security}")
    else
      resp = upsert_failed_task("service_account_mapping", "✖️  FAILED: Service accounts automatically mapped #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Check if security services are being used to harden the application"
task "linux_hardening", ["kubescape_scan"] do |_, args|
  next if args.named["offline"]?

  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "linux_hardening" } if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Linux hardening")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security = "🔓🔑"
    if test_report.failed_resources.size == 0
      upsert_passed_task("linux_hardening", "✔️  ✨PASSED: Security services are being used to harden applications #{emoji_security}")
    else
      resp = upsert_failed_task("linux_hardening", "✖️  ✨FAILED: Found resources that do not use security services #{emoji_security}")
        test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
        stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Check if the containers have insecure capabilities."
task "insecure_capabilities", ["kubescape_scan"] do |_, args|
  next if args.named["offline"]?

  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "insecure_capabilities" } if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Insecure capabilities")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security = "🔓🔑"
    if test_report.failed_resources.size == 0
      upsert_passed_task("insecure_capabilities", "✔️  PASSED: Containers with insecure capabilities were not found #{emoji_security}")
    else
      resp = upsert_failed_task("insecure_capabilities", "✖️  FAILED: Found containers with insecure capabilities #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Check if the containers have resource limits defined."
task "resource_policies", ["kubescape_scan"] do |_, args|
  next if args.named["offline"]?

  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "resource_policies" } if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Resource policies")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security = "🔓🔑"
    if test_report.failed_resources.size == 0
      upsert_passed_task("resource_policies", "✔️  🏆 PASSED: Containers have resource limits defined #{emoji_security}")
    else
      resp = upsert_failed_task("resource_policies", "✖️  🏆 FAILED: Found containers without resource limits defined #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Check Ingress and Egress traffic policy"
task "ingress_egress_blocked", ["kubescape_scan"] do |_, args|
  next if args.named["offline"]?

  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "ingress_egress_blocked" } if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Ingress and Egress blocked")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security = "🔓🔑"
    if test_report.failed_resources.size == 0
      upsert_passed_task("ingress_egress_blocked", "✔️  ✨PASSED: Ingress and Egress traffic blocked on pods #{emoji_security}")
    else
      resp = upsert_failed_task("ingress_egress_blocked", "✖️  ✨FAILED: Ingress and Egress traffic not blocked on pods #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Check the Host PID/IPC privileges of the containers"
task "host_pid_ipc_privileges", ["kubescape_scan"] do |_, args|
  next if args.named["offline"]?

  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "host_pid_ipc_privileges" } if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Host PID/IPC privileges")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security = "🔓🔑"
    if test_report.failed_resources.size == 0
      upsert_passed_task("host_pid_ipc_privileges", "✔️  PASSED: No containers with hostPID and hostIPC privileges #{emoji_security}")
    else
      resp = upsert_failed_task("host_pid_ipc_privileges", "✖️  FAILED: Found containers with hostPID and hostIPC privileges #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Check if the containers are running with non-root user with non-root group membership"
task "non_root_containers", ["kubescape_scan"] do |_, args|
  next if args.named["offline"]?

  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "non_root_containers" } if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Non-root containers")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security = "🔓🔑"
    if test_report.failed_resources.size == 0
      upsert_passed_task("non_root_containers", "✔️  🏆 PASSED: Containers are running with non-root user with non-root group membership #{emoji_security}")
    else
      resp = upsert_failed_task("non_root_containers", "✖️  🏆 FAILED: Found containers running with root user or user with root group membership #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Check that privileged containers are not used"
task "privileged_containers", ["kubescape_scan" ] do |_, args|
  next if args.named["offline"]?

  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "privileged_containers" } if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Privileged container")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security = "🔓🔑"
    #todo whitelist
    if test_report.failed_resources.size == 0
      upsert_passed_task("privileged_containers", "✔️  🏆 PASSED: No privileged containers were found #{emoji_security}")
    else
      resp = upsert_failed_task("privileged_containers", "✖️  🏆 FAILED: Found privileged containers #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Check if containers have immutable file systems"
task "immutable_file_systems", ["kubescape_scan"] do |_, args|
  next if args.named["offline"]?

  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "immutable_file_systems" } if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Immutable container filesystem")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security = "🔓🔑"
    if test_report.failed_resources.size == 0
      upsert_passed_task("immutable_file_systems", "✔️  ✨PASSED: Containers have immutable file systems #{emoji_security}")
    else
      resp = upsert_failed_task("immutable_file_systems", "✖️  ✨FAILED: Found containers with mutable file systems #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end

desc "Check if containers have hostPath mounts"
task "hostpath_mounts", ["kubescape_scan"] do |_, args|
  next if args.named["offline"]?

  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "hostpath_mounts" } if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Allowed hostPath")
    test_report = Kubescape.parse_test_report(test_json)
    resource_keys = CNFManager.workload_resource_keys(args, config)
    test_report = Kubescape.filter_cnf_resources(test_report, resource_keys)

    emoji_security = "🔓🔑"
    if test_report.failed_resources.size == 0
      upsert_passed_task("hostpath_mounts", "✔️  PASSED: Containers do not have hostPath mounts #{emoji_security}")
    else
      resp = upsert_failed_task("hostpath_mounts", "✖️  FAILED: Found containers with hostPath mounts #{emoji_security}")
      test_report.failed_resources.map {|r| stdout_failure(r.alert_message) }
      stdout_failure("Remediation: #{test_report.remediation}")
      resp
    end
  end
end
