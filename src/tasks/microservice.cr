require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "The CNF conformance suite checks to see if CNFs follows microservice principles"
task "microservice", ["image_size_large"] do |_, args|
end

desc "Is the image size large?"
task "image_size_large" do |_, args|
  begin
    # Parse the cnf-conformance.yml
    micro_size = `curl -s -H "Authorization: JWT " "https://hub.docker.com/v2/repositories/coredns/coredns/tags/?page_size=100" | jq -r '.results[] | select(.name == "latest") | .full_size'`.split('\n')[0] 
    curl_success = $?.success?
     
    # config = cnf_conformance_yml
    #
    # found = 0
    # current_cnf_dir_short_name = cnf_conformance_dir
    # puts current_cnf_dir_short_name if check_verbose(args)
    # destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    # puts destination_cnf_dir if check_verbose(args)
    # install_script = config.get("install_script").as_s?
    # if install_script
    # response = String::Builder.new
    # content = File.open("#{destination_cnf_dir}/#{install_script}") do |file|
    #   file.gets_to_end
    # end
    # puts content
    # if /helm/ =~ content 
    #   found = 1
    # end
    # if curl_success && !micro_size && micro_size.to_i > 5000000000
    #   upsert_failed_task("image_size_large")
    #   puts "FAILURE: Image size too large".colorize(:red)
    # else
    #   upsert_passed_task("image_size_large")
    #   puts "PASSED: Image size is good".colorize(:green)
    # end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end


