# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"
require "../utils/docker_client.cr"
require "halite"
require "totem"

desc "The CNF conformance suite checks to see if CNFs follows microservice principles"
task "microservice", ["reasonable_image_size", "reasonable_startup_time"] do |_, args|
  stdout_score("microservice")
end

desc "Does the CNF have a reasonable startup time?"
task "reasonable_startup_time" do |_, args|
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "reasonable_startup_time" if check_verbose(args)

    # config = get_parsed_cnf_conformance_yml(args)
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    # yml_file_path = cnf_conformance_yml_file_path(args)
    # needs to be the source directory
    yml_file_path = CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String))
    LOGGING.info("reasonable_startup_time yml_file_path: #{yml_file_path}")
    VERBOSE_LOGGING.info "yaml_path: #{yml_file_path}" if check_verbose(args)

    helm_chart = "#{config.get("helm_chart").as_s?}"
    helm_directory = "#{config.get("helm_directory").as_s?}"
    release_name = "#{config.get("release_name").as_s?}"
    deployment_name = "#{config.get("deployment_name").as_s?}"
    current_dir = FileUtils.pwd 
    #helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    helm = CNFSingleton.helm
    VERBOSE_LOGGING.info helm if check_verbose(args)

    create_namespace = `kubectl create namespace startup-test`
    helm_template_orig = ""
    helm_template_test = ""
    kubectl_apply = ""
    is_kubectl_applied = ""
    is_kubectl_deployed = ""
    elapsed_time = Time.measure do
      LOGGING.info("reasonable_startup_time helm_chart.empty?: #{helm_chart.empty?}")
      unless helm_chart.empty?
        LOGGING.info("reasonable_startup_time #{helm} template #{release_name} #{helm_chart} > #{yml_file_path}/reasonable_startup_orig.yml")
        LOGGING.info "helm_template_orig command: #{helm} template #{release_name} #{helm_chart} > #{yml_file_path}/reasonable_startup_orig.yml}"
        helm_template_orig = `#{helm} template #{release_name} #{helm_chart} > #{yml_file_path}/reasonable_startup_orig.yml`
        LOGGING.info("reasonable_startup_time #{helm} template --namespace=startup-test #{release_name} #{helm_chart} > #{yml_file_path}/reasonable_startup_test.yml")
        helm_template_test = `#{helm} template --namespace=startup-test #{release_name} #{helm_chart} > #{yml_file_path}/reasonable_startup_test.yml`
        VERBOSE_LOGGING.info "helm_chart: #{helm_chart}" if check_verbose(args)
      else
        LOGGING.info("reasonable_startup_time #{helm} template #{release_name} #{yml_file_path}/#{helm_directory} > #{yml_file_path}/reasonable_startup_orig.yml")
        helm_template_orig = `#{helm} template #{release_name} #{yml_file_path}/#{helm_directory} > #{yml_file_path}/reasonable_startup_orig.yml`
        LOGGING.info("reasonable_startup_time #{helm} template --namespace=startup-test #{release_name} #{yml_file_path}/#{helm_directory} > #{yml_file_path}/reasonable_startup_test.yml")
        helm_template_test = `#{helm} template --namespace=startup-test #{release_name} #{yml_file_path}/#{helm_directory} > #{yml_file_path}/reasonable_startup_test.yml`
        VERBOSE_LOGGING.info "helm_directory: #{helm_directory}" if check_verbose(args)
      end
      kubectl_apply = `kubectl apply -f #{yml_file_path}/reasonable_startup_test.yml --namespace=startup-test`
      is_kubectl_applied = $?.success?
      CNFManager.wait_for_install(deployment_name, wait_count=180,"startup-test")
      is_kubectl_deployed = $?.success?
    end

    VERBOSE_LOGGING.info helm_template_test if check_verbose(args)
    VERBOSE_LOGGING.info kubectl_apply if check_verbose(args)
    VERBOSE_LOGGING.info "installed? #{is_kubectl_applied}" if check_verbose(args)
    VERBOSE_LOGGING.info "deployed? #{is_kubectl_deployed}" if check_verbose(args)

    emoji_fast="🚀"
    emoji_slow="🐢"
    if is_kubectl_applied && is_kubectl_deployed && elapsed_time.seconds < 30
      upsert_passed_task("reasonable_startup_time", "✔️  PASSED: CNF had a reasonable startup time #{emoji_fast}")
    else
      upsert_failed_task("reasonable_startup_time", "✖️  FAILURE: CNF had a startup time of #{elapsed_time.seconds} seconds #{emoji_slow}")
    end

   ensure
    delete_namespace = `kubectl delete namespace startup-test --force --grace-period 0 2>&1 >/dev/null`
    rollback_non_namespaced = `kubectl apply -f #{yml_file_path}/reasonable_startup_orig.yml`
    # CNFManager.wait_for_install(deployment_name, wait_count=180)
  end
end

desc "Does the CNF have a reasonable container image size?"
task "reasonable_image_size", ["retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "reasonable_image_size" if check_verbose(args)
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    # TODO loop through all deployments in the helm chart 
    yml_file_path = CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String))
    LOGGING.info("reasonable_startup_time yml_file_path: #{yml_file_path}")
    VERBOSE_LOGGING.info "yaml_path: #{yml_file_path}" if check_verbose(args)
    helm_directory = "#{config.get("helm_directory").as_s?}"
    release_name = "#{config.get("release_name").as_s?}"
    helm_chart_path = yml_file_path + "/" + helm_directory
    manifest_file_path = yml_file_path + "/" + "temp_template.yml"
    # get the manifest file from the helm chart
    # TODO if no release name, then assume bare manifest file/directory with no helm chart
    Helm.generate_manifest_from_templates(release_name, 
                                          helm_chart_path, 
                                          manifest_file_path)
    template_ymls = Helm.read_template_as_ymls(manifest_file_path) 
    deployment_ymls = Helm.workload_resource_by_kind(template_ymls, Helm::DEPLOYMENT)
    deployment_names = Helm.workload_resource_names(deployment_ymls)
    LOGGING.info "deployment names: #{deployment_names}"
    if deployment_names && deployment_names.size > 0 
      test_passed = true
    else
      test_passed = false
    end
    deployment_names.each do | deployment |
      VERBOSE_LOGGING.debug deployment.inspect if check_verbose(args)
      containers = KubectlClient::Get.deployment_containers(deployment)
      local_image_tags = KubectlClient::Get.container_image_tags(containers)
      local_image_tags.each do |x|
        dockerhub_image_tags = DockerClient::Get.image_tags(x[:image])
        image_by_tag = DockerClient::Get.image_by_tag(dockerhub_image_tags, x[:tag])
        micro_size = image_by_tag && image_by_tag["full_size"] 
        VERBOSE_LOGGING.info "micro_size: #{micro_size.to_s}" if check_verbose(args)
        unless dockerhub_image_tags && dockerhub_image_tags.status_code == 200 && micro_size.to_s.to_i64 < 5_000_000_000
          puts "deployment: #{deployment} and container: #{x[:image]}:#{x[:tag]} Failed".colorize(:red)
          test_passed=false
        end
      end
    end

    emoji_image_size="⚖️👀"
    emoji_small="🐜"
    emoji_big="🦖"

    # if a sucessfull call and size of container is less than 5gb (5 billion bytes)
    if test_passed
      upsert_passed_task("reasonable_image_size", "✔️  PASSED: Image size is good #{emoji_small} #{emoji_image_size}")
    else
      upsert_failed_task("reasonable_image_size", "✖️  FAILURE: Image size too large #{emoji_big} #{emoji_image_size}")
    end
  end
end


