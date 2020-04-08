require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils.cr"

desc "CNF containers should be isolated from one another and the host.  The CNF Conformance suite uses tools like Falco, Sysdig Inspect and gVisor"
task "security", ["privileged"] do |_, args|
end

desc "Check if any containers are running in privileged mode"
task "privileged" do |_, args|
  #TODO Document all arguments
  #TODO check if container exists
  #TODO Check if args exist
  begin
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
      upsert_failed_task("privileged")
      puts "FAILURE: #{violation_list.size} Found privileged containers: #{violation_list.inspect}".colorize(:red)
    else
      upsert_passed_task("privileged")
      puts "PASSED: No privileged containers".colorize(:green)
    end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end
