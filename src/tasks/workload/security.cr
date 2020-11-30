require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "CNF containers should be isolated from one another and the host.  The CNF Conformance suite uses tools like Falco, Sysdig Inspect and gVisor"
task "security", ["privileged"] do |_, args|
  stdout_score("security")
end

desc "Check if any containers are running in privileged mode"
task "privileged" do |_, args|
  #TODO Document all arguments
  #TODO check if container exists
  #TODO Check if args exist
  task_runner(args) do |args|
    VERBOSE_LOGGING.info "privileged" if check_verbose(args)
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))

    helm_chart_container_name = config.get("helm_chart_container_name").as_s
    white_list_container_name = config.get("white_list_helm_chart_container_names").as_a
    VERBOSE_LOGGING.info "helm_chart_container_name #{helm_chart_container_name}" if check_verbose(args)
    VERBOSE_LOGGING.info "white_list_container_name #{white_list_container_name.inspect}" if check_verbose(args)
    privileged_response = `kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[?(@.securityContext.privileged==true)].name}'`
    VERBOSE_LOGGING.info "privileged_response #{privileged_response}" if check_verbose(args)
    privileged_list = privileged_response.to_s.split(" ").uniq
    VERBOSE_LOGGING.info "privileged_list #{privileged_list}" if check_verbose(args)
    # TODO add container list from k8s api
    deployment_name = config.get("deployment_name").as_s
    containers = KubectlClient::Get.deployment_containers(deployment_name)
    white_list_containers = ((PRIVILEGED_WHITELIST_CONTAINERS + white_list_container_name) - [containers.as_a])
    violation_list = (privileged_list - white_list_containers)
    emoji_security="🔓🔑"
    if privileged_list.find {|x| x == helm_chart_container_name} ||
        violation_list.size > 0
      upsert_failed_task("privileged", "✖️  FAILURE: Found #{violation_list.size} privileged containers: #{violation_list.inspect} #{emoji_security}")
    else
      upsert_passed_task("privileged", "✔️  PASSED: No privileged containers #{emoji_security}")
    end
  end
end
