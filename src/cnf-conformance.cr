require "sam"
require "./tasks/**"

desc "The CNF Conformance program enables interoperability of CNFs from multiple vendors running on top of Kubernetes supplied by different vendors. The goal is to provide an open source test suite to enable both open and closed source CNFs to demonstrate conformance and implementation of best practices."
task "all", ["all_prereqs", "configuration_file_setup", "compatibility","stateless", "security", "scalability", "configuration_lifecycle", "observability", "installability", "hardware_affinity", "microservice"] do  |_, args|
  puts "all" if check_verbose(args)

  total = total_points
  if total > 0
    puts "Final score: #{total}".colorize(:green)
  else
    puts "Final score: #{total}".colorize(:red)
  end

  if failed_required_tasks.size > 0
    puts "Conformance Suite failed!".colorize(:red)
    puts "Failed required tasks: #{failed_required_tasks.inspect}".colorize(:red)
  end

  new_results = create_final_results_yml_name
  results = `mv #{LOGFILE} #{new_results}`
  puts "Results have been saved to #{new_results}"
end

task "all_prereqs" do |_, args|
  puts "all_prereqs" if check_verbose(args)
  puts "args = #{args.inspect}" if check_verbose(args)
  if args.named.keys.includes? "cnf-config"
    yml_file = args.named["cnf-config"].as(String)
    cnf = File.dirname(yml_file)
    puts "all cnf: #{cnf}" if check_verbose(args)
    if args.named["deploy_with_chart"]? && args.named["deploy_with_chart"] == "false"
      deploy_with_chart = false
    else
      deploy_with_chart = true
    end
    sample_setup_args(sample_dir: cnf, deploy_with_chart: deploy_with_chart, args: args, verbose: check_verbose(args) )
	end
end

Sam.help
