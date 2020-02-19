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
  privileged_response = `kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[?(@.securityContext.privileged==true)].name}'`
  puts "privileged_response #{privileged_response}" if check_verbose(args)
  privileged_list = privileged_response.to_s.split(" ").uniq
  puts "privileged_list #{privileged_list}" if check_verbose(args)
  if privileged_list.size == 0 
    puts "PASSED: No privileged containers".colorize(:green)
  else
    puts "FAILURE: #{privileged_list.size} privileged containers!".colorize(:red)
  end
end
