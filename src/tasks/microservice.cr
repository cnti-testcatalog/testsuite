# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"
require "halite"
require "totem"

desc "The CNF conformance suite checks to see if CNFs follows microservice principles"
task "microservice", ["reasonable_image_size", "reasonable_startup_time"] do |_, args|
  total = total_points("microservice")
  if total > 0
    puts "Microservice final score: #{total} of #{total_max_points("microservice")}".colorize(:green)
  else
    puts "Microservice final score: #{total} of #{total_max_points("microservice")}".colorize(:red)
  end
end

desc "Does the CNF have a reasonable startup time?"
task "reasonable_startup_time" do |_, args|
  task_response = task_runner(args) do |args|
    puts "reasonable_startup_time" if check_verbose(args)

    # config = get_parsed_cnf_conformance_yml(args)
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    # yml_file_path = cnf_conformance_yml_file_path(args)
    # needs to be the source directory
    yml_file_path = ensure_cnf_conformance_dir(args.named["cnf-config"].as(String))
    # yml_file_path = cnf_destination_dir(ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    LOGGING.info("reasonable_startup_time yml_file_path: #{yml_file_path}")
    puts "yaml_path: #{yml_file_path}" if check_verbose(args)

    startup_timeout = 60

    helm_chart = "#{config.get("helm_chart").as_s?}"
    helm_directory = "#{config.get("helm_directory").as_s?}"
    release_name = "#{config.get("release_name").as_s?}"
    deployment_name = "#{config.get("deployment_name").as_s?}"
    current_dir = FileUtils.pwd 
    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    puts helm if check_verbose(args)

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
        helm_template_orig = `#{helm} template #{release_name} #{helm_chart} > #{yml_file_path}/reasonable_startup_orig.yml`
        LOGGING.info("reasonable_startup_time #{helm} template --namespace=startup-test #{release_name} #{helm_chart} > #{yml_file_path}/reasonable_startup_test.yml")
        helm_template_test = `#{helm} template --namespace=startup-test #{release_name} #{helm_chart} > #{yml_file_path}/reasonable_startup_test.yml`
        puts "helm_chart: #{helm_chart}" if check_verbose(args)
      else
        LOGGING.info("reasonable_startup_time #{helm} template #{release_name} #{yml_file_path}/#{helm_directory} > #{yml_file_path}/reasonable_startup_orig.yml")
        helm_template_orig = `#{helm} template #{release_name} #{yml_file_path}/#{helm_directory} > #{yml_file_path}/reasonable_startup_orig.yml`
        LOGGING.info("reasonable_startup_time #{helm} template --namespace=startup-test #{release_name} #{yml_file_path}/#{helm_directory} > #{yml_file_path}/reasonable_startup_test.yml")
        helm_template_test = `#{helm} template --namespace=startup-test #{release_name} #{yml_file_path}/#{helm_directory} > #{yml_file_path}/reasonable_startup_test.yml`
        puts "helm_directory: #{helm_directory}" if check_verbose(args)
      end
      kubectl_apply = `kubectl apply -f #{yml_file_path}/reasonable_startup_test.yml --namespace=startup-test`
      is_kubectl_applied = $?.success?
      wait_for_install(deployment_name, wait_count=180,"startup-test")
      is_kubectl_deployed = $?.success?
    end

    puts helm_template_test if check_verbose(args)
    puts kubectl_apply if check_verbose(args)
    puts "installed? #{is_kubectl_applied}" if check_verbose(args)
    puts "deployed? #{is_kubectl_deployed}" if check_verbose(args)

    if is_kubectl_applied && is_kubectl_deployed && elapsed_time.seconds < startup_timeout
      upsert_passed_task("reasonable_startup_time")
      puts "✔️  PASSED: CNF had a reasonable startup time 🚀".colorize(:green)
    else
      upsert_failed_task("reasonable_startup_time")
      puts "✖️  FAILURE: CNF had a startup time of #{elapsed_time.seconds} seconds 🐢".colorize(:red)
    end

    delete_namespace = `kubectl delete namespace startup-test --force --grace-period 0 2>&1 >/dev/null`
    rollback_non_namespaced = `kubectl apply -f #{yml_file_path}/reasonable_startup_orig.yml`

  end
end

desc "Does the CNF have a reasonable container image size?"
task "reasonable_image_size", ["retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args|
    # config = cnf_conformance_yml
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    helm_directory = config.get("helm_directory").as_s
    # current_cnf_dir_short_name = cnf_conformance_dir
    # puts current_cnf_dir_short_name if check_verbose(args)
    # destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    destination_cnf_dir = cnf_destination_dir(ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    #TODO get the docker repository segment from the helm chart
    #TODO check all images
    # helm_chart_values = JSON.parse(`#{tools_helm} get values #{release_name} -a --output json`)
    # image_name = helm_chart_values["image"]["repository"]
    docker_repository = config.get("docker_repository").as_s?
    puts "docker_repository: #{docker_repository}"if check_verbose(args)
    deployment = Totem.from_file "#{destination_cnf_dir}/#{helm_directory}/manifest.yml"
    puts deployment.inspect if check_verbose(args)
    containers = deployment.get("spec").as_h["template"].as_h["spec"].as_h["containers"].as_a
    image_tag = [] of Array(Hash(Int32, String))
     image_tag = containers.map do |container|
       {image: container.as_h["image"].as_s.split(":")[0],
        tag: container.as_h["image"].as_s.split(":")[1]}
    end
    puts "image_tag: #{image_tag.inspect}" if check_verbose(args)
    if docker_repository
      # e.g. `curl -s -H "Authorization: JWT " "https://hub.docker.com/v2/repositories/#{docker_repository}/tags/?page_size=100" | jq -r '.results[] | select(.name == "latest") | .full_size'`.split('\n')[0] 
      docker_resp = Halite.get("https://hub.docker.com/v2/repositories/#{image_tag[0][:image]}/tags/?page_size=100", headers: {"Authorization" => "JWT"})
      latest_image = docker_resp.parse("json")["results"].as_a.find{|x|x["name"]=="#{image_tag[0][:tag]}"} 
      micro_size = latest_image && latest_image["full_size"] 
    else
      puts "no docker repository specified" if check_verbose(args)
      micro_size = nil 
    end

    puts "micro_size: #{micro_size.to_s}" if check_verbose(args)

    # if a sucessfull call and size of container is less than 5gb
    if docker_repository && 
        docker_resp &&
        docker_resp.status_code == 200 && 
        micro_size.to_s.to_i64 < 50000000
      upsert_passed_task("reasonable_image_size")
      puts "✔️  PASSED: Image size is good".colorize(:green)
    else
      upsert_failed_task("reasonable_image_size")
      puts "✖️  FAILURE: Image size too large".colorize(:red)
    end
  end
end


