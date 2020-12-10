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
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    helm_directory = "#{config.get("helm_directory").as_s?}"
    manifest_directory = optional_key_as_string(config, "manifest_directory")
    release_name = "#{config.get("release_name").as_s?}"
    helm_chart_path = destination_cnf_dir + "/" + helm_directory
    manifest_file_path = destination_cnf_dir + "/" + "temp_template.yml"

    if release_name.empty? # no helm chart
      template_ymls = Helm::Manifest.manifest_ymls_from_file_list(Helm::Manifest.manifest_file_list( destination_cnf_dir + "/" + manifest_directory))
    else
      Helm.generate_manifest_from_templates(release_name, 
                                          helm_chart_path, 
                                          manifest_file_path)
      template_ymls = Helm::Manifest.parse_manifest_as_ymls(manifest_file_path) 
    end

    deployment_ymls = Helm.workload_resource_by_kind(template_ymls, Helm::DEPLOYMENT)
    deployment_names = Helm.workload_resource_names(deployment_ymls)
    LOGGING.info "deployment names: #{deployment_names}"
    if deployment_names && deployment_names.size > 0 
      test_passed = true
    else
      puts "No deployment names found for container kill test".colorize(:red)
    end

    containers = deployment_names.map { | deployment_name |
      KubectlClient::Get.deployment_containers(deployment_name).as_a.map do |c|
        c["name"]
      end
    }.flatten  

    white_list_container_name = config.get("white_list_helm_chart_container_names").as_a
    VERBOSE_LOGGING.info "white_list_container_name #{white_list_container_name.inspect}" if check_verbose(args)
    VERBOSE_LOGGING.info "installed container names #{containers.inspect}" if check_verbose(args)

    privileged_list = KubectlClient::Get.privileged_containers
    white_list_containers = ((PRIVILEGED_WHITELIST_CONTAINERS + white_list_container_name) - [containers])
    # Only check the containers that are in the deployed helm chart or manifest
    violation_list = privileged_list & (containers - white_list_containers)
    LOGGING.info "violator list: #{violation_list}"
    emoji_security="🔓🔑"
    # TODO use list of names in containers variable
    # if privileged_list.find {|x| x == helm_chart_container_name} ||
    #     violation_list.size > 0
    if violation_list.size > 0
      upsert_failed_task("privileged", "✖️  FAILURE: Found #{violation_list.size} privileged containers: #{violation_list.inspect} #{emoji_security}")
    else
      upsert_passed_task("privileged", "✔️  PASSED: No privileged containers #{emoji_security}")
    end
  end
end
