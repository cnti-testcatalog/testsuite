require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils.cr"

desc "The CNF conformance suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s kubectl"
task "installability", ["install_script_helm"] do |_, args|
end

desc "Does the install script use helm?"
task "install_script_helm" do |_, args|
  begin
    # Parse the cnf-conformance.yml
    config = cnf_conformance_yml

    found = 0
    install_script = config.get("install_script").as_s
    response = String::Builder.new
    content = File.open(install_script) do |file|
      file.gets_to_end
    end
    # puts content
    if /helm/ =~ content 
      found = 1
    end
    if found < 1
      puts "FAILURE: Helm not found in install script".colorize(:red)
    else
      puts "PASSED: Helm found in install script".colorize(:green)
    end
  rescue ex
    puts ex.message
  end
end


