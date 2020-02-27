require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils.cr"

desc "CNF containers should be isolated from one another and the host.  The CNF Conformance suite uses tools like Falco, Sysdig Inspect and gVisor"
task "security" do |_, args|
end

desc "Check if any containers are running in privileged mode"
task "privileged" do |_, args|
  #TODO Document all arguments
  #TODO check if container exists
  #TODO Check if args exist
  #TODO Set sane defaults for args
  #TODO Get a list of whitelist containers 
  #TODO Get list of priviliged containers
  #TODO Remove containers that are on white list
  #TODO If privileged containers count > 0 Error, else pass
  config = cnf_conformance_yml
  helm_chart_container_name = config.get("helm_chart_container_name").as_s
  white_list_container_name = config.get("white_list_helm_chart_container_names").as_a
  puts "helm_chart_container_name #{helm_chart_container_name}" if check_verbose(args)
  puts "white_list_container_name #{white_list_container_name.inspect}" if check_verbose(args)
  privileged_response = `kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[?(@.securityContext.privileged==true)].name}'`
  puts "privileged_response #{privileged_response}" if check_verbose(args)
  privileged_list = privileged_response.to_s.split(" ").uniq
  puts "privileged_list #{privileged_list}" if check_verbose(args)
  violation_list = (privileged_list - white_list_container_name)
  if privileged_list.find {|x| x == helm_chart_container_name} ||
      violation_list.size > 0
    puts "FAILURE: #{violation_list.size} privileged containers: #{violation_list.inspect}".colorize(:red)
  else
    puts "PASSED: No privileged containers".colorize(:green)
  end
end
