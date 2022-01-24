# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

rolling_version_change_test_names = ["rolling_update", "rolling_downgrade", "rolling_version_change"]

desc "The CNF test suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s kubectl"
task "compatibility", ["install_script_helm", "helm_chart_valid", "helm_chart_published", "helm_deploy", "cni_compatible", "increase_decrease_capacity", "rollback"].concat(rolling_version_change_test_names) do |_, args|
  stdout_score("compatibility", "Compatibility, Installability, and Upgradeability")

end
rolling_version_change_test_names.each do |tn|
  pretty_test_name = tn.split(/:|_/).join(" ")
  pretty_test_name_capitalized = tn.split(/:|_/).map(&.capitalize).join(" ")

  desc "Test if the CNF containers are loosely coupled by performing a #{pretty_test_name}"
  task "#{tn}" do |_, args|
    CNFManager::Task.task_runner(args) do |args, config|
      LOGGING.debug "cnf_config: #{config}"
      VERBOSE_LOGGING.info "#{tn}" if check_verbose(args)
      container_names = config.cnf_config[:container_names]
      LOGGING.debug "container_names: #{container_names}"
      update_applied = true
      unless container_names
        puts "Please add a container names set of entries into your cnf-testsuite.yml".colorize(:red)
        update_applied = false
      end

      # TODO use tag associated with image name string (e.g. busybox:v1.7.9) as the version tag
      # TODO optional get a valid version from the remote repo and roll to that, if no tag
      #  e.g. wget -q https://registry.hub.docker.com/v1/repositories/debian/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}'
      # note: all images are not on docker hub nor are they always on a docker hub compatible api

      task_response = update_applied && CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
        test_passed = true
        valid_cnf_testsuite_yml = true
        LOGGING.debug "#{tn} container: #{container}"
        LOGGING.debug "container_names: #{container_names}"
        config_container = container_names.find{|x| x["name"]==container.as_h["name"]} if container_names
        LOGGING.debug "config_container: #{config_container}"
        unless config_container && config_container["#{tn}_test_tag"]? && !config_container["#{tn}_test_tag"].empty?
          puts "Please add the container name #{container.as_h["name"]} and a corresponding #{tn}_test_tag into your cnf-testsuite.yml under container names".colorize(:red)
          valid_cnf_testsuite_yml = false
        end

        VERBOSE_LOGGING.debug "#{tn}: #{container} valid_cnf_testsuite_yml=#{valid_cnf_testsuite_yml}" if check_verbose(args)
        VERBOSE_LOGGING.debug "#{tn}: #{container} config_container=#{config_container}" if check_verbose(args)
        if valid_cnf_testsuite_yml && config_container
          resp = KubectlClient::Set.image(resource["name"],
                                          container.as_h["name"],
                                          # split out image name from version tag
                                          container.as_h["image"].as_s.rpartition(":")[0],
                                          config_container["#{tn}_test_tag"])
        else
          resp = false
        end
        # If any containers dont have an update applied, fail
        test_passed = false if resp == false

        rollout_status = KubectlClient::Rollout.resource_status(resource["kind"], resource["name"], timeout="60s")
        unless rollout_status
          test_passed = false
        end
        VERBOSE_LOGGING.debug "#{tn}: #{container} test_passed=#{test_passed}" if check_verbose(args)
        test_passed
      end
      VERBOSE_LOGGING.debug "#{tn}: task_response=#{task_response}" if check_verbose(args)
      if task_response
        resp = upsert_passed_task("#{tn}","✔️  PASSED: CNF for #{pretty_test_name_capitalized} Passed" )
      else
        resp = upsert_failed_task("#{tn}", "✖️  FAILED: CNF for #{pretty_test_name_capitalized} Failed")
      end
      resp
      # TODO should we roll the image back to original version in an ensure?
      # TODO Use the kubectl rollback to history command
    end
  end
end

desc "Check if the CNF is running kubernetes services with external IP's configured?"
task "restrict_external_ips" do |_, args|
  Log.for("verbose").info { "restrict-external-ips" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/restrict-service-external-ips/restrict-service-external-ips.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

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


desc "Check if the CNF is running containers with container sock mounts?"
task "disallow_container_sock_mounts" do |_, args|
  Log.for("verbose").info { "disallow-container-sock-mounts" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/disallow_cri_sock_mount/disallow_cri_sock_mount.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "disallow-container-sock-mounts"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("disallow_container_sock_mounts", "✔️  PASSED: Containers are not using container sock mounts #{emoji_passed}")
  else
    resp = upsert_failed_task("disallow_container_sock_mounts", "✔️  FAILED: Use of the container sock mount is not allowed #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using container Unix socket".colorize(:red)
      end
    end
  end
end


desc "Check if the CNF is running containers in default namespace?"
task "disallow_default_namespace" do |_, args|
  Log.for("verbose").info { "disallow-default-namespace" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/disallow_default_namespace/disallow_default_namespace.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  sleep(3.seconds)
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "disallow-default-namespace"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

#  sleep(1.minutes)

  if test_passed
    resp = upsert_passed_task("disallow_default_namespace", "✔️  PASSED: Containers are not running in default namespace #{emoji_passed}")
  else
    resp = upsert_failed_task("disallow_default_namespace", "✔️  FAILED: Using default namespace is not allowed #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using default namespace".colorize(:red)
      end
    end
  end
end


desc "Check if the CNF is running containers with name tiller in their image name?"
task "disallow_helm_tiller" do |_, args|
  Log.for("verbose").info { "disallow-helm-tiller" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/disallow_helm_tiller/disallow_helm_tiller.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

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


desc "Check if the CNF is running containers with labels configured?"
task "require_labels" do |_, args|
  Log.for("verbose").info { "require-labels" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/require_labels/require_labels.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "require-labels"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("require_labels", "✔️  PASSED: Containers are configured with labels #{emoji_passed}")
  else
    resp = upsert_failed_task("require_labels", "✔️  FAILED: The label `app.kubernetes.io/name` is required for containers. #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is not configured with labels".colorize(:red)
      end
    end
  end
end


desc "Check if the CNF is running containers with CPU and memory requests and limits configured?"
task "require_requests_limits" do |_, args|
  Log.for("verbose").info { "require-requests-limits" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/require_pod_requests_limits/require_pod_requests_limits.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "require-requests-limits"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("require_requests_limits", "✔️  PASSED: Containers are configured with CPU and memory requests and limits #{emoji_passed}")
  else
    resp = upsert_failed_task("require_requests_limits", "✔️  FAILED: CPU and memory resource requests and limits are required for the containers. #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is not configured with CPU and memory requests and limits".colorize(:red)
      end
    end
  end
end

desc "Check if the CNF is running containers with liveness and readiness probe configured?"
task "require_pod_probes" do |_, args|
  Log.for("verbose").info { "require-pod-probes" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/require_probes/require_probes.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "require-pod-probes"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("require_pod_probes", "✔️  PASSED: Containers are configured with liveness and readiness probe #{emoji_passed}")
  else
    resp = upsert_failed_task("require_pod_probes", "✔️  FAILED: Liveness and readiness probes are required. #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is not configured with liveness and readiness probes".colorize(:red)
      end
    end
  end
end

desc "Check if the CNF is running any service of type nodeport?"
task "restrict_nodeport" do |_, args|
  Log.for("verbose").info { "restrict-nodeport" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/restrict_node_port/restrict_node_port.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "restrict-nodeport"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("restrict_nodeport", "✔️  PASSED: There are no service with type nodeport running #{emoji_passed}")
  else
    resp = upsert_failed_task("restrict_nodeport", "✔️  FAILED: Services of type NodePort are not allowed. #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using a service of type nodePort".colorize(:red)
      end
    end
  end
end


desc "Check if the CNF is running any containers with non-core volume types that are not allowed?"
task "restrict_volume_types" do |_, args|
  Log.for("verbose").info { "restrict-volume-types" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/pod-security/restricted/restrict-volume-types/restrict-volume-types.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "restrict-volume-types"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("restrict_volume_types", "✔️  PASSED: Containers are not using volumes types that are blocked #{emoji_passed}")
  else
    resp = upsert_failed_task("restrict_volume_types", "✔️  FAILED: Use of certain non-core volume types is restricted. #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using a one of the non core volume type which is not allowed".colorize(:red)
      end
    end
  end
end

desc "Check if the CNF is running any containers with custom seccomp profile?"
task "restrict_seccomp" do |_, args|
  Log.for("verbose").info { "restrict-seccomp" }

  policy_url = "https://raw.githubusercontent.com/nsagark/policies/main/pod-security/restricted/restrict-seccomp/restrict-seccomp.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "restrict-seccomp"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("restrict_seccomp", "✔️  PASSED: Containers are not using custom seccomp profiles #{emoji_passed}")
  else
    resp = upsert_failed_task("restrict_seccomp", "✔️  FAILED: Use of custom Seccomp profiles is disallowed #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using a custom seccomp profile".colorize(:red)
      end
    end
  end
end


desc "Check if the CNF is running any containers running as root?"
task "run_as_non_root" do |_, args|
  Log.for("verbose").info { "run-as-non-root" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/pod-security/restricted/require-run-as-nonroot/require-run-as-nonroot.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "require-run-as-non-root"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("run_as_non_root", "✔️  PASSED: Containers are running as nonroot #{emoji_passed}")
  else
    resp = upsert_failed_task("run_as_non_root", "✔️  FAILED: Containers must be required to run as non-root users #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is running as root user".colorize(:red)
      end
    end
  end
end

desc "Check if the CNF is using non root groups for its containers?"
task "require_non_root_groups" do |_, args|
  Log.for("verbose").info { "require-non-root-groups" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/pod-security/restricted/require-non-root-groups/require-non-root-groups.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "require-non-root-groups"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("require_non_root_groups", "✔️  PASSED: Containers are using non root groups #{emoji_passed}")
  else
    resp = upsert_failed_task("require_non_root_groups", "✔️  FAILED: Containers are forbidden from running with a root primary or supplementary GID. The runAsGroup, supplementalGroups, and f
sGroup fields must be set to a number greater than zero #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using a non root groups".colorize(:red)
      end
    end
  end
end


desc "Check if the CNF is allowing privilege escalation for its containers?"
task "deny_privilege_escalation" do |_, args|
  Log.for("verbose").info { "deny-privilege-escalation" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/pod-security/restricted/deny-privilege-escalation/deny-privilege-escalation.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "deny-privilege-escalation"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("deny_privilege_escalation", "✔️  PASSED: Containers are not using privilege escalation #{emoji_passed}")
  else
    resp = upsert_failed_task("deny_privilege_escalation", "✔️  FAILED: Privilege escalation is disallowed. The fields spec.containers[*].securityContext.allowPrivilegeEscalation, and spec.in
itContainers[*].securityContext.allowPrivilegeEscalation must be undefined or set to `false #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using privilege escalation".colorize(:red)
      end
    end
  end
end

desc "Check if the CNF is using safe subsets for its containers?"
task "restrict_sysctls" do |_, args|
  Log.for("verbose").info { "restrict-sysctls" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/pod-security/baseline/restrict-sysctls/restrict-sysctls.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "restrict-sysctls"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("restrict_sysctls", "✔️  PASSED: Containers are using safe sysctl subsets #{emoji_passed}")
  else
    resp = upsert_failed_task("restrict_sysctls", "✔️  FAILED: Setting additional sysctls above the allowed type is disallowed. The field spec.securityContext.sysctls must not use any other n
ames than 'kernel.shm_rmid_forced', 'net.ipv4.ip_local_port_range', 'net.ipv4.tcp_syncookies' and 'net.ipv4.ping_group_range' #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using additional sysctls above the allowed type".colorize(:red)
      end
    end
  end
end


desc "Check if the CNF is using custom SELinux options for its containers?"
task "disallow_selinux" do |_, args|
  Log.for("verbose").info { "disallow-selinux" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/pod-security/baseline/disallow-selinux/disallow-selinux.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "disallow-selinux"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("disallow_selinux", "✔️  PASSED: Containers are not using custom SELinux options #{emoji_passed}")
  else
    resp = upsert_failed_task("disallow_selinux", "✔️  FAILED: Setting custom SELinux options is disallowed as it can be used to escalate privileges #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using a seLinuxOptions field".colorize(:red)
      end
    end
  end
end

desc "Check if the CNF is using privileged containers?"
task "disallow_privileged_containers" do |_, args|
  Log.for("verbose").info { "disallow-privileged-containers" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/pod-security/baseline/disallow-privileged-containers/disallow-privileged-containers.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "disallow-privileged-containers"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("disallow_privileged_containers", "✔️  PASSED: Containers are not using privileged mode #{emoji_passed}")
  else
    resp = upsert_failed_task("disallow_privileged_containers", "✔️  FAILED: Privileged mode is disallowed. The fields spec.containers[*].securityContext.privileged and spec.initContainers[*]
.securityContext.privileged must not be set to true #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is running in privileged mode".colorize(:red)
      end
    end
  end
end


desc "Check if the CNF is using host ports for its containers?"
task "disallow_host_ports" do |_, args|
  Log.for("verbose").info { "disallow-host-ports" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/pod-security/baseline/disallow-host-ports/disallow-host-ports.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "disallow-host-ports"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("disallow_host_ports", "✔️  PASSED: Containers are not using host ports #{emoji_passed}")
  else
    resp = upsert_failed_task("disallow_host_ports", "✔️  FAILED: Use of host ports is disallowed. The fields spec.containers[*].ports[*].hostPort and spec.initContainers[*].ports[*].hostPort
 must be empty #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using a hostport which is not allowed by the policy".colorize(:red)
      end
    end
  end
end

desc "Check if the CNF is using hostpath volumes for its containers?"
task "disallow_host_path" do |_, args|
  Log.for("verbose").info { "disallow-host-path" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/pod-security/baseline/disallow-host-path/disallow-host-path.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "disallow-host-path"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("disallow_host_path", "✔️  PASSED: Containers are not using hostpath volumes #{emoji_passed}")
  else
    resp = upsert_failed_task("disallow_host_path", "✔️  FAILED: HostPath volumes are forbidden. The fields spec.volumes[*].hostPath must not be set for containers #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using a hostpath volume".colorize(:red)
      end
    end
  end
end


desc "Check if the CNF is using host namespaces for its containers?"
task "disallow_host_namespaces" do |_, args|
  Log.for("verbose").info { "disallow-host-namespaces" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/pod-security/baseline/disallow-host-namespaces/disallow-host-namespaces.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "disallow-host-namespaces"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("disallow_host_namespaces", "✔️  PASSED: Containers are not using host namespaces #{emoji_passed}")
  else
    resp = upsert_failed_task("disallow_host_namespaces", "✔️  FAILED: Containers should not be allowed access to host namespaces. The fields spec.hostNetwork, spec.hostIPC, and spec.hostPID
must not be set to true #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using a host namespace".colorize(:red)
      end
    end
  end
end


desc "Check if the CNF is using additional capabilities for its containers?"
task "disallow_add_capabilities" do |_, args|
  Log.for("verbose").info { "disallow-add-capabilities" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/pod-security/baseline/disallow-adding-capabilities/disallow-adding-capabilities.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "disallow-add-capabilities"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("disallow_add_capabilities", "✔️  PASSED: Containers are not using additional capabilities #{emoji_passed}")
  else
    resp = upsert_failed_task("disallow_add_capabilities", "✔️  FAILED: Users cannot add any additional capabilities to a pod beyond the default set #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using additional capabilities".colorize(:red)
      end
    end
  end
end

desc "Check if the CNF is using the latest tag for its images?"
task "disallow_latest_tag" do |_, args|
  Log.for("verbose").info { "disallow-latest-tag" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/disallow_latest_tag/disallow_latest_tag.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️     ✔️"
  emoji_failed="🏷️     ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "disallow-latest-tag"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("disallow_latest_tag", "✔️  PASSED: Container images are not using the latest tag #{emoji_passed}")
  else
    resp = upsert_failed_task("disallow_latest_tag", "✔️  FAILED: Container images cannot use the latest tag #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is using the latest image tag".colorize(:red)
      end
    end
  end
end

#desc "Check if the CNF is using images with latest tag"
#task "latest_tag" do |_, args|
#  Log.for("verbose").info { "latest_tag" }

#  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/disallow_latest_tag/disallow_latest_tag.yaml"
#  apply_result = KubectlClient::Apply.file(policy_url)

#  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")

#  policy_report = JSON.parse(result[:output])
#  test_passed = true
#  failures = [] of String
#  policy_report["results"].as_a.each do |test_result|
#    if test_result["result"] == "fail"
#      test_passed = false
#      failures.push(test_result["message"].as_s)
#    end
#  end
#
#  emoji_passed="🏷️✔️"
#  emoji_failed="🏷️❌"
#
#  if test_passed
#    resp = upsert_passed_task("check_latest_tag", "✔️  PASSED: Images do not use latest tag #{emoji_passed}")
#  else
#    resp = upsert_failed_task("check_latest_tag","✖️  FAILED: Found images with latest tag #{emoji_failed}")
#    failures.each do |msg|
#      puts "Policy Failure: #{msg}".colorize(:red)
#    end
#  end
#end

desc "Check if the CNF is dropping all capabilities and only adding ones that are required"
task "drop_all" do |_, args|
  Log.for("verbose").info { "drop_all" }

  policy_url = "https://raw.githubusercontent.com/nsagark/policies/main/best-practices/require_drop_all/require_drop_all.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
  result = KubectlClient::Get.policy_report("polr-ns-default")

  emoji_passed="🏷️    ✔️"
  emoji_failed="🏷️    ❌"

  policy_report = JSON.parse(result[:output])
  failures = [] of String
  policy_report["results"].as_a.each do |test_result|
    if test_result["result"] == "fail" && test_result["policy"] == "drop-all-capabilities"
      test_passed = false
      resp = upsert_failed_task("check_drop_all","✖️  FAILED: All capabilities should be dropped from a Pod, with only those required added back #{emoji_failed}")
      puts "#{test_result["resources"]}".colorize(:red)
    end
  end
end

desc "Check if the CNF is dropping the CAP_NET_RAW capability"
task "drop_cap_net_raw" do |_, args|
  Log.for("verbose").info { "drop_cap_net_raw" }

  policy_url = "https://raw.githubusercontent.com/nsagark/policies/main/best-practices/require_drop_cap_net_raw/require_drop_cap_net_raw.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
  result = KubectlClient::Get.policy_report("polr-ns-default")

  emoji_passed="🏷️   ✔️"
  emoji_failed="🏷️   ❌"

  policy_report = JSON.parse(result[:output])
  failures = [] of String
  policy_report["results"].as_a.each do |test_result|
    if test_result["result"] == "fail" && test_result["policy"] == "drop-cap-net-raw"
      test_passed = false
      resp = upsert_failed_task("drop_CAP_NET_RAW","✖️  FAILED: CAP_NET_RAW capability should be dropped from a Pod #{emoji_failed}")
      puts "#{test_result["resources"]}".colorize(:red)
    end
  end
end


desc "Check if the CNF has read only root filesystem?"
task "require_ro_rootfs" do |_, args|
  Log.for("verbose").info { "require_ro_rootfs" }

  policy_url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/require_ro_rootfs/require_ro_rootfs.yaml"
  apply_result = KubectlClient::Apply.file(policy_url)
  sleep(3.seconds)
  # TODO move this to a generic kubectl helper to fetch resource OR move to kyverno module
#  result = KubectlClient::Get.policy_report("polr-ns-default")
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️    ✔️"
  emoji_failed="🏷️    ❌"

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "require-ro-rootfs"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end

  if test_passed
    resp = upsert_passed_task("require_ro_rootfs", "✔️  PASSED: Root filesystem is read-only #{emoji_passed}")
  else
    resp = upsert_failed_task("require_ro_rootfs", "✔️  FAILED: Root filesystem must be read-only #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace does not have a read-only filesystem".colorize(:red)
      end
    end
  end
end

desc "This policy will create a new NetworkPolicy resource named `default-deny` which will deny all traffic anytime a new Namespace is created"
task "add_default_network_policy" do |_, args|
  kyverno_version="1.5.0"
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/add_network_policy.yaml"
#  url = "https://raw.githubusercontent.com/nsagark/nginx/main/install.yaml?token=AVOW2YXCWWYMYX7PFYJ6ZBLBU7ZQC"
  result = KubectlClient::Apply.file(url)

  if !result[:status].success?
    puts "Policy could not be applied"
    exit 1
  else
    puts "add_default_network_policy was applied successfully"
  end
end

desc "This policy will report if any containers are pulling images from a non-allowed list of image registries"
task "restrict_image_registries" do |_, args|
  Log.for("verbose").info { "restrict-image-registries" }

  url = "https://raw.githubusercontent.com/kyverno/policies/main/best-practices/restrict_image_registries/restrict_image_registries.yaml"
#  url = "https://raw.githubusercontent.com/nsagark/nginx/main/install.yaml?token=AVOW2YXCWWYMYX7PFYJ6ZBLBU7ZQC"
  apply_result = KubectlClient::Apply.file(url)
  sleep(3.seconds)
  result = KubectlClient::Get.policy_report_allnamespaces()
  emoji_passed="🏷️      ✔️"
  emoji_failed="🏷️      ❌  "

  policy_report = JSON.parse(result[:output])
  test_passed = true

  failures = [] of JSON::Any
  policy_report["items"].as_a.each do |item|
    item["results"].as_a.each do |test_result|
      if test_result["result"] == "fail" && test_result["policy"] == "restrict-image-registries"
        test_passed = false
        failures.push(test_result["resources"])
      end
    end
  end


  if test_passed
    resp = upsert_passed_task("restrict_image_registries", "✔️  PASSED: Containers are using the images from the allowed list of image registries #{emoji_passed}")
  else
    resp = upsert_failed_task("restrict_image_registries", "✖️  FAILED: Containers are not using the images from the allowed list of image registries #{emoji_failed}")
    failures.each do |failure_resources|
      failure_resources.as_a.each do |failure|
        puts "#{failure["kind"]} #{failure["name"]} in #{failure["namespace"]} namespace is pulling image from an unknown image registry".colorize(:red)
      end
    end
  end
end

desc "Test if the CNF can perform a rollback"
task "rollback" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "rollback" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"

    container_names = config.cnf_config[:container_names]
    LOGGING.debug "container_names: #{container_names}"

    update_applied = true
    rollout_status = true
    rollback_status = true
    version_change_applied = true

    unless container_names
      puts "Please add a container names set of entries into your cnf-testsuite.yml".colorize(:red)
      update_applied = false
    end

    task_response = update_applied && CNFManager.workload_resource_test(args, config) do |resource, container, initialized|

        deployment_name = resource["name"]
        container_name = container.as_h["name"]
        full_image_name_tag = container.as_h["image"].as_s.rpartition(":")
        image_name = full_image_name_tag[0]
        image_tag = full_image_name_tag[2]

        VERBOSE_LOGGING.debug "deployment_name: #{deployment_name}" if check_verbose(args)
        VERBOSE_LOGGING.debug "container_name: #{container_name}" if check_verbose(args)
        VERBOSE_LOGGING.debug "image_name: #{image_name}" if check_verbose(args)
        VERBOSE_LOGGING.debug "image_tag: #{image_tag}" if check_verbose(args)
        LOGGING.debug "rollback: setting new version"
        #do_update = `kubectl set image deployment/coredns-coredns coredns=coredns/coredns:latest --record`

        version_change_applied = true
        # compare cnf_testsuite.yml container list with the current container name
        config_container = container_names.find{|x| x["name"] == container_name } if container_names
        unless config_container && config_container["rollback_from_tag"]? && !config_container["rollback_from_tag"].empty?
          puts "Please add the container name #{container.as_h["name"]} and a corresponding rollback_from_tag into your cnf-testsuite.yml under container names".colorize(:red)
          version_change_applied = false
        end
        if version_change_applied && config_container
          rollback_from_tag = config_container["rollback_from_tag"]

          if rollback_from_tag == image_tag
            fail_msg = "✖️  FAILED: please specify a different version than the helm chart default image.tag for 'rollback_from_tag' "
            puts fail_msg.colorize(:red)
            version_change_applied=false
          end

          VERBOSE_LOGGING.debug "rollback: update deployment: #{deployment_name}, container: #{container_name}, image: #{image_name}, tag: #{rollback_from_tag}" if check_verbose(args)
          # set a temporary image/tag, so that we can rollback to the current (original) tag later
          version_change_applied = KubectlClient::Set.image(deployment_name,
                                                            container_name,
                                                            image_name,
                                                            rollback_from_tag)
        end

        LOGGING.info "rollback version change successful? #{version_change_applied}"

        VERBOSE_LOGGING.debug "rollback: checking status new version" if check_verbose(args)
        rollout_status = KubectlClient::Rollout.status(deployment_name, timeout="60s")
        if  rollout_status == false
          puts "Rolling update failed on resource: #{deployment_name} and container: #{container_name}".colorize(:red)
        end

        # https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-to-a-previous-revision
        VERBOSE_LOGGING.debug "rollback: rolling back to old version" if check_verbose(args)
        rollback_status = KubectlClient::Rollout.undo(deployment_name)

    end


    if task_response && version_change_applied && rollout_status && rollback_status
      upsert_passed_task("rollback","✔️  PASSED: CNF Rollback Passed" )
    else
      upsert_failed_task("rollback", "✖️  FAILED: CNF Rollback Failed")
    end
  end
end

desc "Test increasing/decreasing capacity"
task "increase_decrease_capacity", ["increase_capacity", "decrease_capacity"] do |t, args|
  VERBOSE_LOGGING.info "increase_decrease_capacity" if check_verbose(args)
end


def increase_decrease_capacity_failure_msg(target_replicas, emoji)
<<-TEMPLATE
✖️  FAILURE: Replicas did not reach #{target_replicas} #{emoji}

Replica failure can be due to insufficent permissions, image pull errors and other issues.
Learn more on remediation by viewing our USAGE.md doc at https://bit.ly/capacity_remedy

TEMPLATE
end

desc "Test increasing capacity by setting replicas to 1 and then increasing to 3"
task "increase_capacity" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "increase_capacity" if check_verbose(args)
    emoji_increase_capacity="📦📈"

    target_replicas = "3"
    base_replicas = "1"
    # TODO scale replicatsets separately
    # https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#scaling-a-replicaset
    # resource["kind"].as_s.downcase == "replicaset"
    task_response = CNFManager.cnf_workload_resources(args, config) do | resource|
      if resource["kind"].as_s.downcase == "deployment" ||
          resource["kind"].as_s.downcase == "statefulset"
        final_count = change_capacity(base_replicas, target_replicas, args, config, resource)
        target_replicas == final_count
      else
        true
      end
    end
    # if target_replicas == final_count 
    if task_response.none?(false) 
      upsert_passed_task("increase_capacity", "✔️  PASSED: Replicas increased to #{target_replicas} #{emoji_increase_capacity}")
    else
      upsert_failed_task("increase_capacity", increase_decrease_capacity_failure_msg(target_replicas, emoji_increase_capacity))
    end
  end
end

desc "Test decrease capacity by setting replicas to 3 and then decreasing to 1"
task "decrease_capacity" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "decrease_capacity" if check_verbose(args)
    target_replicas = "1"
    base_replicas = "3"
    task_response = CNFManager.cnf_workload_resources(args, config) do | resource|
      # TODO scale replicatsets separately
      # https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#scaling-a-replicaset
      # resource["kind"].as_s.downcase == "replicaset"
      if resource["kind"].as_s.downcase == "deployment" ||
          resource["kind"].as_s.downcase == "statefulset"
        final_count = change_capacity(base_replicas, target_replicas, args, config, resource)
        target_replicas == final_count
      else
        true
      end
    end
    emoji_decrease_capacity="📦📉"

    # if target_replicas == final_count 
    if task_response.none?(false) 
      upsert_passed_task("decrease_capacity", "✔️  PASSED: Replicas decreased to #{target_replicas} #{emoji_decrease_capacity}")
    else
      upsert_failed_task("decrease_capacity", increase_decrease_capacity_failure_msg(target_replicas, emoji_decrease_capacity))
    end
  end
end

def change_capacity(base_replicas, target_replica_count, args, config, resource = {kind: "", 
                                                                                   metadata: {name: ""}})
  VERBOSE_LOGGING.info "change_capacity" if check_verbose(args)
  VERBOSE_LOGGING.debug "increase_capacity args.raw: #{args.raw}" if check_verbose(args)
  VERBOSE_LOGGING.debug "increase_capacity args.named: #{args.named}" if check_verbose(args)
  VERBOSE_LOGGING.info "base replicas: #{base_replicas}" if check_verbose(args)
  LOGGING.debug "resource: #{resource}"

  initialization_time = base_replicas.to_i * 10
  VERBOSE_LOGGING.info "resource: #{resource["metadata"]["name"]}" if check_verbose(args)

  scale_cmd = ""

  case resource["kind"].as_s.downcase
  when "deployment"
    scale_cmd = "#{resource["kind"]}.v1.apps/#{resource["metadata"]["name"]} --replicas=#{base_replicas}"
  when "statefulset"
    scale_cmd = "statefulsets #{resource["metadata"]["name"]} --replicas=#{base_replicas}"
  else #TODO what else can be scaled?
    scale_cmd = "#{resource["kind"]}.v1.apps/#{resource["metadata"]["name"]} --replicas=#{base_replicas}"
  end
  KubectlClient::Scale.command(scale_cmd)

  initialized_count = wait_for_scaling(resource, base_replicas, args)

  if check_verbose(args)
    if initialized_count != base_replicas
      VERBOSE_LOGGING.info "#{resource["kind"]} initialized to #{initialized_count} and could not be set to #{base_replicas}" 
    else
      VERBOSE_LOGGING.info "#{resource["kind"]} initialized to #{initialized_count}"
    end
  end

  case resource["kind"].as_s.downcase
  when "deployment"
    scale_cmd = "#{resource["kind"]}.v1.apps/#{resource["metadata"]["name"]} --replicas=#{target_replica_count}"
  when "statefulset"
    scale_cmd = "statefulsets #{resource["metadata"]["name"]} --replicas=#{target_replica_count}"
  else #TODO what else can be scaled?
    scale_cmd = "#{resource["kind"]}.v1.apps/#{resource["metadata"]["name"]} --replicas=#{target_replica_count}"
  end
  KubectlClient::Scale.command(scale_cmd)

  current_replicas = wait_for_scaling(resource, target_replica_count, args)
  current_replicas
end

def wait_for_scaling(resource, target_replica_count, args)
  VERBOSE_LOGGING.info "target_replica_count: #{target_replica_count}" if check_verbose(args)
  if args.named.keys.includes? "wait_count"
    wait_count_value = args.named["wait_count"]
  else
    wait_count_value = "30"
  end
  wait_count = wait_count_value.to_i
  second_count = 0
  current_replicas = "0"
  replicas_cmd = "kubectl get #{resource["kind"]} #{resource["metadata"]["name"]} -o=jsonpath='{.status.readyReplicas}'"
  Process.run(
    replicas_cmd,
    shell: true,
    output: replicas_stdout = IO::Memory.new,
    error: replicas_stderr = IO::Memory.new
  )
  previous_replicas = replicas_stdout.to_s
  until current_replicas == target_replica_count || second_count > wait_count
    Log.for("verbose").debug { "secound_count: #{second_count} wait_count: #{wait_count}" } if check_verbose(args)
    Log.for("verbose").info { "current_replicas before get #{resource["kind"]}: #{current_replicas}" } if check_verbose(args)
    sleep 1
    Log.for("verbose").debug { "$KUBECONFIG = #{ENV.fetch("KUBECONFIG", nil)}" } if check_verbose(args)

    Process.run(
      replicas_cmd,
      shell: true,
      output: replicas_stdout = IO::Memory.new,
      error: replicas_stderr = IO::Memory.new
    )
    current_replicas = replicas_stdout.to_s

    Log.for("verbose").info { "current_replicas after get #{resource["kind"]}: #{current_replicas.inspect}" } if check_verbose(args)

    if current_replicas.empty?
      current_replicas = "0"
      previous_replicas = "0"
    end

    if current_replicas.to_i != previous_replicas.to_i
      second_count = 0
      previous_replicas = current_replicas
    end
    second_count = second_count + 1 
    Log.for("verbose").info { "previous_replicas: #{previous_replicas}" } if check_verbose(args)
    Log.for("verbose").info { "current_replicas: #{current_replicas}" } if check_verbose(args)
  end
  current_replicas
end 

desc "Will the CNF install using helm with helm_deploy?"
task "helm_deploy" do |_, args|
  unless check_destructive(args)
    Log.info { "skipping helm_deploy: not in destructive mode" }
    puts "SKIPPED: Helm Deploy".colorize(:yellow)
    next
  end
  Log.info { "Running helm_deploy in destructive mode!" }
  Log.for("verbose").info { "helm_deploy" } if check_verbose(args)
  Log.info { "helm_deploy args: #{args.inspect}" }
  if check_cnf_config(args) || CNFManager.destination_cnfs_exist?
    CNFManager::Task.task_runner(args) do |args, config|
      
      emoji_helm_deploy="⎈🚀"
      helm_chart = config.cnf_config[:helm_chart]
      helm_directory = config.cnf_config[:helm_directory]
      release_name = config.cnf_config[:release_name]
      yml_file_path = config.cnf_config[:yml_file_path]
      configmap = KubectlClient::Get.configmap("cnf-testsuite-#{release_name}-startup-information")
      #TODO check if json is empty
      helm_used = configmap["data"].as_h["helm_used"].as_s

      if helm_used == "true" 
        upsert_passed_task("helm_deploy", "✔️  PASSED: Helm deploy successful #{emoji_helm_deploy}")
      else
        upsert_failed_task("helm_deploy", "✖️  FAILED: Helm deploy failed #{emoji_helm_deploy}")
      end
    end
  else
    upsert_failed_task("helm_deploy", "✖️  FAILED: No cnf_testsuite.yml found! Did you run the setup task?")
  end
end

desc "Does the install script use helm?"
task "install_script_helm" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    # config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_testsuite_yml_path(args.named["cnf-config"].as(String)))
    
    emoji_helm_script="⎈📦"
    found = 0
    # destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_testsuite_dir(args.named["cnf-config"].as(String)))
    # install_script = config.get("install_script").as_s?
    install_script = config.cnf_config[:install_script]
    Log.info { "install_script: #{install_script}" }
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    Log.info { "destination_cnf_dir: #{destination_cnf_dir}" }
    Log.for("verbose").debug { destination_cnf_dir } if check_verbose(args)
    if !install_script.empty?
      response = String::Builder.new
      content = File.open("#{destination_cnf_dir}/#{install_script}") do |file|
        file.gets_to_end
      end
      # LOGGING.debug content
      if /helm/ =~ content
        found = 1
      end
      if found < 1
        upsert_failed_task("install_script_helm", "✖️  FAILED: Helm not found in supplied install script #{emoji_helm_script}")
      else
        upsert_passed_task("install_script_helm", "✔️  PASSED: Helm found in supplied install script #{emoji_helm_script}")
      end
    else
      upsert_passed_task("install_script_helm", "✔️  PASSED (by default): No install script provided")
    end
  end
end

task "helm_chart_published", ["helm_local_install"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    if check_verbose(args)
      Log.for("verbose").info { "helm_chart_published" }
      Log.for("verbose").debug { "helm_chart_published args.raw: #{args.raw}" }
      Log.for("verbose").debug { "helm_chart_published args.named: #{args.named}" }
    end

    # config = cnf_testsuite_yml
    # config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_testsuite_yml_path(args.named["cnf-config"].as(String)))
    # helm_chart = "#{config.get("helm_chart").as_s?}"
    helm_chart = config.cnf_config[:helm_chart]
    emoji_published_helm_chart="⎈📦🌐"
    current_dir = FileUtils.pwd
    helm = BinarySingleton.helm
    Log.for("verbose").debug { helm } if check_verbose(args)

    if CNFManager.helm_repo_add(args: args)
      unless helm_chart.empty?
        helm_search_cmd = "#{helm} search repo #{helm_chart}"
        Log.info { "helm search command: #{helm_search_cmd}" }
        Process.run(
          helm_search_cmd,
          shell: true,
          output: helm_search_stdout = IO::Memory.new,
          error: helm_search_stderr = IO::Memory.new
        )
        helm_search = helm_search_stdout.to_s
        Log.for("verbose").debug { "#{helm_search}" } if check_verbose(args)
        unless helm_search =~ /No results found/
          upsert_passed_task("helm_chart_published", "✔️  PASSED: Published Helm Chart Found #{emoji_published_helm_chart}")
        else
          upsert_failed_task("helm_chart_published", "✖️  FAILED: Published Helm Chart Not Found #{emoji_published_helm_chart}")
        end
      else
        upsert_failed_task("helm_chart_published", "✖️  FAILED: Published Helm Chart Not Found #{emoji_published_helm_chart}")
      end
    else
      upsert_failed_task("helm_chart_published", "✖️  FAILED: Published Helm Chart Not Found #{emoji_published_helm_chart}")
    end
  end
end

task "helm_chart_valid", ["helm_local_install"] do |_, args|
  CNFManager::Task.task_runner(args) do |args|
    if check_verbose(args)
      Log.for("verbose").info { "helm_chart_valid" }
      Log.for("verbose").debug { "helm_chart_valid args.raw: #{args.raw}" }
      Log.for("verbose").debug { "helm_chart_valid args.named: #{args.named}" }
    end

    response = String::Builder.new

    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_testsuite_yml_path(args.named["cnf-config"].as(String)))
    # helm_directory = config.get("helm_directory").as_s
    helm_directory = optional_key_as_string(config, "helm_directory")
    if helm_directory.empty?
      working_chart_directory = "exported_chart"
    else
      working_chart_directory = helm_directory
    end

    if args.named.keys.includes? "cnf_chart_path"
      working_chart_directory = args.named["cnf_chart_path"]
    end

    Log.for("verbose").debug { "working_chart_directory: #{working_chart_directory}" } if check_verbose(args)

    current_dir = FileUtils.pwd
    Log.for("verbose").debug { current_dir } if check_verbose(args)
    helm = BinarySingleton.helm
    emoji_helm_lint="⎈📝☑️"

    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_testsuite_dir(args.named["cnf-config"].as(String)))

    helm_lint_cmd = "#{helm} lint #{destination_cnf_dir}/#{working_chart_directory}"
    helm_lint_status = Process.run(
      helm_lint_cmd,
      shell: true,
      output: helm_lint_stdout = IO::Memory.new,
      error: helm_link_stderr = IO::Memory.new
    )
    helm_lint = helm_lint_stdout.to_s
    Log.for("verbose").debug { "helm_lint: #{helm_lint}" } if check_verbose(args)

    if helm_lint_status.success?
      upsert_passed_task("helm_chart_valid", "✔️  PASSED: Helm Chart #{working_chart_directory} Lint Passed #{emoji_helm_lint}")
    else
      upsert_failed_task("helm_chart_valid", "✖️  FAILED: Helm Chart #{working_chart_directory} Lint Failed #{emoji_helm_lint}")
    end
  end
end

task "validate_config" do |_, args|
  yml = CNFManager.parsed_config_file(CNFManager.ensure_cnf_testsuite_yml_path(args.named["cnf-config"].as(String)))
  valid, warning_output = CNFManager.validate_cnf_testsuite_yml(yml)
  emoji_config="📋"
  if valid
    stdout_success "✔️ PASSED: CNF configuration validated #{emoji_config}"
  else
    stdout_failure "❌ FAILED: Critical Error with CNF Configuration. Please review USAGE.md for steps to set up a valid CNF configuration file #{emoji_config}"
  end
end

def setup_calico_cluster(cluster_name : String, offline : Bool) : KindManager::Cluster
  if offline
    Log.info { "Running cni_compatible(Cluster Creation) in Offline Mode" }

    chart_directory = "#{TarClient::TAR_REPOSITORY_DIR}/projectcalico_tigera-operator"
    chart = Dir.entries("#{chart_directory}")[1]
    status = `docker image load -i #{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/kind-node.tar`
    Log.info { "#{status}" }
    Log.info { "Installing Airgapped CNI Chart: #{chart_directory}/#{chart}" }
    calico_cluster = KindManager.create_cluster_with_chart_and_wait(
      cluster_name,
      KindManager.disable_cni_config,
      "#{chart_directory}/#{chart} --namespace calico",
      offline
    )
    ENV["KUBECONFIG"]="#{calico_cluster.kubeconfig}"
    #TODO Don't bootstrap all images, only Calico & Cilium are needed.
    if Dir.exists?("#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}")
      AirGap.cache_images(kind_name: "calico-test-control-plane" )
      AirGap.cache_images(cnf_setup: true, kind_name: "calico-test-control-plane" )
    else
      puts "Bootstrap directory is missing, please run ./cnf-testsuite setup offline=<path-to-your-airgapped.tar.gz>".colorize(:red)
      raise "Bootstrap directory is missing, please run ./cnf-testsuite setup offline=<path-to-your-airgapped.tar.gz>"
    end
  else
    Log.info { "Running cni_compatible(Cluster Creation) in Online Mode" }
    Helm.helm_repo_add("projectcalico","https://docs.projectcalico.org/charts")
    calico_cluster = KindManager.create_cluster_with_chart_and_wait(
      cluster_name,
      KindManager.disable_cni_config,
      "projectcalico/tigera-operator --version v3.20.2",
      offline
    )
  end

  return calico_cluster
end

def setup_cilium_cluster(cluster_name : String, offline : Bool) : KindManager::Cluster
  chart_opts = [
    "--set operator.replicas=1",
    "--set image.repository=cilium/cilium",
    "--set image.useDigest=false",
    "--set operator.image.useDigest=false",
    "--set operator.image.repository=cilium/operator"
  ]

  kind_manager = KindManager.new
  cluster = kind_manager.create_cluster(cluster_name, KindManager.disable_cni_config, offline)

  if offline
    chart_directory = "#{TarClient::TAR_REPOSITORY_DIR}/cilium_cilium"
    chart = Dir.entries("#{chart_directory}")[2]
    Log.info { "Installing Airgapped CNI Chart: #{chart_directory}/#{chart}" }

    chart = "#{chart_directory}/#{chart}"
    Helm.install("#{cluster_name}-plugin #{chart} #{chart_opts.join(" ")} --namespace kube-system --kubeconfig #{cluster.kubeconfig}")

    ENV["KUBECONFIG"]="#{cluster.kubeconfig}"
    if Dir.exists?("#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}")
      AirGap.cache_images(kind_name: "cilium-test-control-plane" )
      AirGap.cache_images(cnf_setup: true, kind_name: "cilium-test-control-plane" )
    else
      puts "Bootstrap directory is missing, please run ./cnf-testsuite setup offline=<path-to-your-airgapped.tar.gz>".colorize(:red)
      raise "Bootstrap directory is missing, please run ./cnf-testsuite setup offline=<path-to-your-airgapped.tar.gz>"
    end
  else
    Helm.helm_repo_add("cilium","https://helm.cilium.io/")
    chart = "cilium/cilium"
    chart_opts.push("--version 1.10.5")
    Helm.install("#{cluster_name}-plugin #{chart} #{chart_opts.join(" ")} --namespace kube-system --kubeconfig #{cluster.kubeconfig}")
  end

  cluster.wait_until_pods_ready()
  Log.info { "cilium kubeconfig: #{cluster.kubeconfig}" }
  return cluster
end

desc "CNFs should work with any Certified Kubernetes product and any CNI-compatible network that meet their functionality requirements."
task "cni_compatible" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "cni_compatible" } if check_verbose(args)

    ensure_kubeconfig!
    kubeconfig_orig = ENV["KUBECONFIG"]

    if args.named["offline"]? && args.named["offline"]? != "false"
      offline = true
    else
      offline = false
    end

    calico_cluster = setup_calico_cluster("calico-test", offline)
    Log.info { "calico kubeconfig: #{calico_cluster.kubeconfig}" }
    calico_cnf_passed = CNFManager.cnf_to_new_cluster(config, calico_cluster.kubeconfig, offline)
    Log.info { "calico_cnf_passed: #{calico_cnf_passed}" }
    puts "CNF failed to install on Calico CNI cluster".colorize(:red) unless calico_cnf_passed

    cilium_cluster = setup_cilium_cluster("cilium-test", offline)
    cilium_cnf_passed = CNFManager.cnf_to_new_cluster(config, cilium_cluster.kubeconfig, offline)
    Log.info { "cilium_cnf_passed: #{cilium_cnf_passed}" }
    puts "CNF failed to install on Cilium CNI cluster".colorize(:red) unless cilium_cnf_passed

    emoji_security="🔓🔑"
    if calico_cnf_passed && cilium_cnf_passed
      upsert_passed_task("cni_compatible", "✔️  PASSED: CNF compatible with both Calico and Cilium #{emoji_security}")
    else
      upsert_failed_task("cni_compatible", "✖️  FAILED: CNF not compatible with either Calico or Cillium #{emoji_security}")
    end
  ensure
    kind_manager = KindManager.new
    kind_manager.delete_cluster("calico-test")
    kind_manager.delete_cluster("cilium-test")
    ENV["KUBECONFIG"]="#{kubeconfig_orig}"
  end
end
