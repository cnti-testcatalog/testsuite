require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "CNF containers should be isolated from one another and the host.  The CNF Conformance suite uses tools like Falco, Sysdig Inspect and gVisor"
task "security", ["privileged"] do |_, args|
  total = total_points("security")
  if total > 0
    puts "Security final score: #{total} of #{total_max_points("security")}".colorize(:green)
  else
    puts "Security final score: #{total} of #{total_max_points("security")}".colorize(:red)
  end
end

desc "Check if any containers are running in privileged mode"
task "privileged" do |_, args|
  #TODO Document all arguments
  #TODO check if container exists
  #TODO Check if args exist
  task_runner(args) do |args|
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))

    helm_chart_container_name = config.get("helm_chart_container_name").as_s
    white_list_container_name = config.get("white_list_helm_chart_container_names").as_a
    puts "helm_chart_container_name #{helm_chart_container_name}" if check_verbose(args)
    puts "white_list_container_name #{white_list_container_name.inspect}" if check_verbose(args)
    privileged_response = `kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[?(@.securityContext.privileged==true)].name}'`
    puts "privileged_response #{privileged_response}" if check_verbose(args)
    privileged_list = privileged_response.to_s.split(" ").uniq
    puts "privileged_list #{privileged_list}" if check_verbose(args)
    white_list_containers = (white_list_container_name - [helm_chart_container_name])
    violation_list = (privileged_list - white_list_containers)
    if privileged_list.find {|x| x == helm_chart_container_name} ||
        violation_list.size > 0
      upsert_failed_task("privileged")
      puts "✖️  FAILURE: Found #{violation_list.size} privileged containers: #{violation_list.inspect}".colorize(:red)
    else
      upsert_passed_task("privileged")
      puts "✔️  PASSED: No privileged containers".colorize(:green)
    end
  end
end
