require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"
require "halite"
require "totem"

desc "The CNF conformance suite checks to see if CNFs follows microservice principles"
task "microservice", ["image_size_large"] do |_, args|
end
desc "Is the image size large?"
task "image_size_large", ["retrieve_manifest"] do |_, args|
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
      upsert_passed_task("image_size_large")
      puts "PASSED: Image size is good".colorize(:green)
    else
      upsert_failed_task("image_size_large")
      puts "FAILURE: Image size too large".colorize(:red)
    end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end


