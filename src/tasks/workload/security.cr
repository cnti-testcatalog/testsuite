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
    "dangerous_capabilities",
    "resource_policies",
    "linux_hardening",
    "ingress_egress_blocked",
    "host_pid_ipc_privileges",
    "non_root_containers",
    "privileged_containers",
    "network_policies",
    "immutable_file_systems",
    "hostpath_mounts",
    "container_sock_mounts"
  ] do |_, args|
  stdout_score("security")
end

desc "Check if the CNF is running kubernetes services with external IP's configured?"
task "restrict_external_ips", ["install_kyverno"] do |_, args|
  unless check_poc(args)
    Log.info { "skipping restrict_external_ips: not in poc mode" }
    puts "SKIPPED: Restrict External IPs".colorize(:yellow)
    next
  end

  Log.for("verbose").info { "restrict-external-ips" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/restrict-service-external-ips/restrict-service-external-ips.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  result = Kyverno::PolicyReport.all()
  emoji_passed="🏷️       ✔️"
  emoji_failed="🏷️       ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "restrict-external-ips"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("restrict_external_ips", "✔️  PASSED: Services are not using external IP's #{emoji_passed}")
  else
    resp = upsert_failed_task("restrict_external_ips", "✔️  FAILED: externalIPs are not allowed in Services #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using external IP which is not allowed".colorize(:red)
      end
    end
  end
end

desc "Check if the CNF is running containers with name tiller in their image name?"
task "disallow_helm_tiller", ["install_kyverno"] do |_, args|
  unless check_poc(args)
    Log.info { "skipping disallow_helm_tiller: not in poc mode" }
    puts "SKIPPED: Disallow Helm Tiller".colorize(:yellow)
    next
  end

  Log.for("verbose").info { "disallow-helm-tiller" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/disallow_helm_tiller/disallow_helm_tiller.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  result = Kyverno::PolicyReport.all()
  emoji_passed="🏷️      ✔️"
  emoji_failed="🏷️      ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "disallow-helm-tiller"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("disallow_helm_tiller", "✔️  PASSED: No containers are running with name tiller in their image names #{emoji_passed}")
  else
    resp = upsert_failed_task("disallow_helm_tiller", "✔️  FAILED: Helm Tiller is not allowed in the image name #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using tiller in the image name".colorize(:red)
      end
    end
  end
end

desc "Check if the CNF is running containers with container sock mounts"
task "container_sock_mounts", ["install_kyverno"] do |_, args|
  Log.for("verbose").info { "container_sock_mounts" }
  policy_path = Kyverno.best_practice_policy("disallow_cri_sock_mount/disallow_cri_sock_mount.yaml")
  apply_result = KubectlClient::Apply.file(policy_path)
  sleep(3.seconds)
  emoji_passed="🏷️      ✔️"
  emoji_failed="🏷️      ❌"
  failures = Kyverno::PolicyReport.failures("disallow-container-sock-mounts")

  if failures.size == 0
    resp = upsert_passed_task("container_sock_mounts", "✔️  PASSED: Container engine daemon sockets are not mounted as volumes #{emoji_passed}")
  else
    resp = upsert_failed_task("container_sock_mounts", "✔️  FAILED: Container engine daemon sockets are mounted as volumes #{emoji_failed}")
    failures.each do |failure|
      failure.resources.each do |resource|
        puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
      end
    end
  end
end

desc "Check if any containers are running in as root"
task "non_root_user", ["install_falco"] do |_, args|
   unless KubectlClient::Get.resource_wait_for_install("Daemonset", "falco", namespace: TESTSUITE_NAMESPACE)
     Log.info { "Falco Failed to Start" }
     upsert_skipped_task("non_root_user", "✖️  SKIPPED: Skipping non_root_user: Falco failed to install. Check Kernel Headers are installed on the Host Systems(K8s).")
     node_pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
     pods = KubectlClient::Get.pods_by_label(node_pods, "app", "falco")
     falco_pod_name = pods[0].dig("metadata", "name").as_s
     Log.info { "Falco Pod Name: #{falco_pod_name}" }
     resp = KubectlClient.logs(falco_pod_name, namespace: TESTSUITE_NAMESPACE)
     next
   end

   CNFManager::Task.task_runner(args) do |args,config|
     Log.for("verbose").info { "non_root_user" } if check_verbose(args)
     Log.debug { "cnf_config: #{config}" }
     fail_msgs = [] of String
     task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
       test_passed = true
       Log.info { "Falco is Running" }
       kind = resource["kind"].as_s.downcase
       case kind 
       when  "deployment","statefulset","pod","replicaset", "daemonset"
         resource_yaml = KubectlClient::Get.resource(resource[:kind], resource[:name])
         pods = KubectlClient::Get.pods_by_resource(resource_yaml)
         # containers = KubectlClient::Get.resource_containers(kind, resource[:name]) 
         pods.map do |pod|
           # containers.as_a.map do |container|
           #   container_name = container.dig("name")
           pod_name = pod.dig("metadata", "name").as_s
           # if Falco.find_root_pod(pod_name, container_name)
           if Falco.find_root_pod(pod_name)
             fail_msg = "resource: #{resource} and pod #{pod_name} uses a root user"
             unless fail_msgs.find{|x| x== fail_msg}
               puts fail_msg.colorize(:red)
               fail_msgs << fail_msg
             end
             test_passed=false
           end
         end
       end
       test_passed
     end
     emoji_no_root="🚫√"
     emoji_root="√"

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
    violation_list = [] of String
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|

      privileged_list = KubectlClient::Get.privileged_containers
      white_list_containers = ((PRIVILEGED_WHITELIST_CONTAINERS + white_list_container_names) - [container])
      # Only check the containers that are in the deployed helm chart or manifest
      (privileged_list & ([container.as_h["name"].as_s] - white_list_containers)).each do |x|
        violation_list << x
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
      upsert_failed_task("privileged", "✖️  FAILED: Found #{violation_list.size} privileged containers: #{violation_list.inspect} #{emoji_security}")
    end
  end
end

desc "Check if any containers are running in privileged mode"
task "privilege_escalation", ["kubescape_scan"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "privilege_escalation" if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Allow privilege escalation")

    emoji_security="🔓🔑"
    if Kubescape.test_passed?(test_json) 
      upsert_passed_task("privilege_escalation", "✔️  PASSED: No containers that allow privilege escalation were found #{emoji_security}")
    else
      resp = upsert_failed_task("privilege_escalation", "✖️  FAILED: Found containers that allow privilege escalation #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
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

    emoji_security="🔓🔑"
    if Kubescape.test_passed?(test_json) 
      upsert_passed_task("symlink_file_system", "✔️  PASSED: No containers allow a symlink attack #{emoji_security}")
    else
      resp = upsert_failed_task("symlink_file_system", "✖️  FAILED: Found containers that allow a symlink attack #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
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

    emoji_security="🔓🔑"
    if Kubescape.test_passed?(test_json) 
      upsert_passed_task("application_credentials", "✔️  PASSED: No applications credentials in configuration files #{emoji_security}")
    else
      resp = upsert_failed_task("application_credentials", "✖️  FAILED: Found applications credentials in configuration files #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
      resp
    end
  end
end

desc "Check if potential attackers may gain access to a POD and inherit access to the entire host network. For example, in AWS case, they will have access to the entire VPC."
task "host_network", ["uninstall_cluster_tools", "kubescape_scan"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "host_network" if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "hostNetwork access")

    emoji_security="🔓🔑"
    if Kubescape.test_passed?(test_json) 
      upsert_passed_task("host_network", "✔️  PASSED: No host network attached to pod #{emoji_security}")
    else
      resp = upsert_failed_task("host_network", "✖️  FAILED: Found host network attached to pod #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
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

    emoji_security="🔓🔑"
    if Kubescape.test_passed?(test_json) 
      upsert_passed_task("service_account_mapping", "✔️  PASSED: No service accounts automatically mapped #{emoji_security}")
    else
      resp = upsert_failed_task("service_account_mapping", "✖️  FAILED: Service accounts automatically mapped #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
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

    emoji_security = "🔓🔑"
    if Kubescape.test_passed?(test_json)
      upsert_passed_task("linux_hardening", "✔️  PASSED: Security services are being used to harden applications #{emoji_security}")
    else
      resp = upsert_failed_task("linux_hardening", "✖️  FAILED: Found resources that do not use security services #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
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

    emoji_security = "🔓🔑"
    if Kubescape.test_passed?(test_json)
      upsert_passed_task("insecure_capabilities", "✔️  PASSED: Containers with insecure capabilities were not found #{emoji_security}")
    else
      resp = upsert_failed_task("insecure_capabilities", "✖️  FAILED: Found containers with insecure capabilities #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
      resp
    end
  end
end

desc "Check if the containers have dangerous capabilities."
task "dangerous_capabilities", ["kubescape_scan"] do |_, args|
  next if args.named["offline"]?

  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "dangerous_capabilities" } if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Dangerous capabilities")

    emoji_security = "🔓🔑"
    if Kubescape.test_passed?(test_json)
      upsert_passed_task("dangerous_capabilities", "✔️  PASSED: Containers with dangerous capabilities were not found #{emoji_security}")
    else
      resp = upsert_failed_task("dangerous_capabilities", "✖️  FAILED: Found containers with dangerous capabilities #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
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

    emoji_security = "🔓🔑"
    if Kubescape.test_passed?(test_json)
      upsert_passed_task("resource_policies", "✔️  PASSED: Containers have resource limits defined #{emoji_security}")
    else
      resp = upsert_failed_task("resource_policies", "✖️  FAILED: Found containers without resource limits defined #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
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

    emoji_security = "🔓🔑"
    if Kubescape.test_passed?(test_json)
      upsert_passed_task("ingress_egress_blocked", "✔️  PASSED: Ingress and Egress traffic blocked on pods #{emoji_security}")
    else
      resp = upsert_failed_task("ingress_egress_blocked", "✖️  FAILED: Ingress and Egress traffic not blocked on pods #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
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

    emoji_security = "🔓🔑"
    if Kubescape.test_passed?(test_json)
      upsert_passed_task("host_pid_ipc_privileges", "✔️  PASSED: No containers with hostPID and hostIPC privileges #{emoji_security}")
    else
      resp = upsert_failed_task("host_pid_ipc_privileges", "✖️  FAILED: Found containers with hostPID and hostIPC privileges #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
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

    emoji_security = "🔓🔑"
    if Kubescape.test_passed?(test_json)
      upsert_passed_task("non_root_containers", "✔️  PASSED: Containers are running with non-root user with non-root group membership #{emoji_security}")
    else
      resp = upsert_failed_task("non_root_containers", "✖️  FAILED: Found containers running with root user or user with root group membership #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
      resp
    end
  end
end

desc "Check if network policies are defined for namespaces"
task "network_policies", ["kubescape_scan"] do |_, args|
  next if args.named["offline"]?

  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "network_policies" } if check_verbose(args)
    results_json = Kubescape.parse
    test_json = Kubescape.test_by_test_name(results_json, "Network policies")

    emoji_security = "🔓🔑"
    if Kubescape.test_passed?(test_json)
      upsert_passed_task("network_policies", "✔️  PASSED: Namespaces have network policies defined #{emoji_security}")
    else
      resp = upsert_failed_task("network_policies", "✖️  FAILED: Found namespaces which do not have network policies defined #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
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

    emoji_security = "🔓🔑"
    #todo whitelist
    if Kubescape.test_passed?(test_json)
      upsert_passed_task("privileged_containers", "✔️  PASSED: No privileged containers were found #{emoji_security}")
    else
      resp = upsert_failed_task("privileged_containers", "✖️  FAILED: Found privileged containers #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
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

    emoji_security = "🔓🔑"
    if Kubescape.test_passed?(test_json)
      upsert_passed_task("immutable_file_systems", "✔️  PASSED: Containers have immutable file systems #{emoji_security}")
    else
      resp = upsert_failed_task("immutable_file_systems", "✖️  FAILED: Found containers with mutable file systems #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
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

    emoji_security = "🔓🔑"
    if Kubescape.test_passed?(test_json)
      upsert_passed_task("hostpath_mounts", "✔️  PASSED: Containers do not have hostPath mounts #{emoji_security}")
    else
      resp = upsert_failed_task("hostpath_mounts", "✖️  FAILED: Found containers with hostPath mounts #{emoji_security}")
      Kubescape.alerts_by_test(test_json).map{|t| puts "\n#{t}".colorize(:red)}
      puts "Remediation: #{Kubescape.remediation(test_json)}\n".colorize(:red)
      resp
    end
  end
end
