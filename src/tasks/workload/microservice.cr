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
  task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "reasonable_startup_time" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"

    yml_file_path = config.cnf_config[:yml_file_path]
    helm_chart = config.cnf_config[:helm_chart]
    helm_directory = config.cnf_config[:helm_directory]
    release_name = config.cnf_config[:release_name]
    
    current_dir = FileUtils.pwd 
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

      template_ymls = Helm::Manifest.parse_manifest_as_ymls("#{yml_file_path}/reasonable_startup_test.yml") 

      LOGGING.debug "template_ymls: #{template_ymls}"
      task_response = template_ymls.map do | resource|
        LOGGING.debug "Waiting on resource: #{resource["metadata"]["name"]} of type #{resource["kind"]}"
        if resource["kind"].as_s.downcase == "deployment" ||
            resource["kind"].as_s.downcase == "pod" ||
            resource["kind"].as_s.downcase == "daemonset" ||
            resource["kind"].as_s.downcase == "statefulset" ||
            resource["kind"].as_s.downcase == "replicaset"

          CNFManager.resource_wait_for_install(resource["kind"], resource["metadata"]["name"], wait_count=180, "startup-test")
          $?.success?
        else
          true
        end
      end
      is_kubectl_deployed = task_response.none?{|x| x == false}
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
    LOGGING.debug "Reasonable startup cleanup"
    delete_namespace = `kubectl delete namespace startup-test --force --grace-period 0 2>&1 >/dev/null`
    rollback_non_namespaced = `kubectl apply -f #{yml_file_path}/reasonable_startup_orig.yml`
    # CNFManager.wait_for_install(deployment_name, wait_count=180)
  end
end

desc "Does the CNF have a reasonable container image size?"
task "reasonable_image_size", ["retrieve_manifest"] do |_, args|
  task_runner(args) do |args,config|
    VERBOSE_LOGGING.info "reasonable_image_size" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
      local_image_tag = {image: container.as_h["image"].as_s.split(":")[0],
                         #TODO an image may not have a tag
                         tag: container.as_h["image"].as_s.split(":")[1]?}

      dockerhub_image_tags = DockerClient::Get.image_tags(local_image_tag[:image])
      image_by_tag = DockerClient::Get.image_by_tag(dockerhub_image_tags, local_image_tag[:tag])
      micro_size = image_by_tag && image_by_tag["full_size"] 
      VERBOSE_LOGGING.info "micro_size: #{micro_size.to_s}" if check_verbose(args)
      unless dockerhub_image_tags && dockerhub_image_tags.status_code == 200 && micro_size.to_s.to_i64 < 5_000_000_000
        puts "resource: #{resource} and container: #{local_image_tag[:image]}:#{local_image_tag[:tag]} Failed".colorize(:red)
        test_passed=false
      end
      test_passed
    end

    emoji_image_size="⚖️👀"
    emoji_small="🐜"
    emoji_big="🦖"

    if task_response 
      upsert_passed_task("reasonable_image_size", "✔️  PASSED: Image size is good #{emoji_small} #{emoji_image_size}")
    else
      upsert_failed_task("reasonable_image_size", "✖️  FAILURE: Image size too large #{emoji_big} #{emoji_image_size}")
    end
  end
end


