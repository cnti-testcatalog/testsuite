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
end

desc "Does the CNF have a reasonable startup time?"
task "reasonable_startup_time" do |_, args|
  begin
    puts "reasonable_startup_time" if check_verbose(args)

    if args.named.keys.includes? "yml-file"
      yml_file = args.named["yml-file"].as(String)
      parsed_cnf_conformance_yml = Totem.from_file "#{yml_file}"
      cnf_conformance_yml_path = yml_file.split("/")[0..-2].reduce(""){|x, acc| x.empty? ? acc : "#{x}/#{acc}"}
      helm_chart = "#{parsed_cnf_conformance_yml.get("helm_chart").as_s?}"
      helm_directory = "#{parsed_cnf_conformance_yml.get("helm_directory").as_s?}"
      release_name = "#{parsed_cnf_conformance_yml.get("release_name").as_s?}"
      deployment_name = "#{parsed_cnf_conformance_yml.get("deployment_name").as_s?}"
    else
      config = cnf_conformance_yml
      helm_chart = "#{config.get("helm_chart").as_s?}"
      helm_directory = "#{config.get("helm_directory").as_s?}"
      release_name = "#{config.get("release_name").as_s?}"
      deployment_name = "#{config.get("deployment_name").as_s?}"
    end

    current_dir = FileUtils.pwd 
    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    puts helm if check_verbose(args)

    helm_install = ""
    elapsed_time = Time.measure do
      unless helm_chart.empty?
        helm_install = `#{helm} install #{release_name} #{helm_chart}`
        puts "helm_chart: #{helm_chart}" if check_verbose(args)

      else
        helm_install = `#{helm} install #{release_name} #{cnf_conformance_yml_path}/#{helm_directory}`
        puts "helm_directory: #{helm_directory}" if check_verbose(args)
      end
      wait_for_install(deployment_name)
    end

    puts helm_install if check_verbose(args)

    # if is_helm_installed
    if elapsed_time.seconds < 30
      upsert_passed_task("reasonable_startup_time")
      puts "PASSED: CNF had a reasonable startup time 🚀".colorize(:green)
    else
      upsert_failed_task("reasonable_startup_time")
      puts "FAILURE: CNF had a startup time of #{elapsed_time.seconds} seconds 🐢".colorize(:red)
    end

  end
end

desc "Does the CNF have a reasonable container image size?"
task "reasonable_image_size", ["retrieve_manifest"] do |_, args|
  begin
    config = cnf_conformance_yml
    helm_directory = config.get("helm_directory").as_s
    current_cnf_dir_short_name = cnf_conformance_dir
    puts current_cnf_dir_short_name if check_verbose(args)
    destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
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
      puts "PASSED: Image size is good".colorize(:green)
    else
      upsert_failed_task("reasonable_image_size")
      puts "FAILURE: Image size too large".colorize(:red)
    end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end


