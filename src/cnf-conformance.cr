require "sam"
require "./tasks/**"
require "./tasks/utils/utils.cr"
require "./tasks/utils/git.cr"
require "./cnf_conformance.cr"


desc "The CNF Conformance program enables interoperability of CNFs from multiple vendors running on top of Kubernetes supplied by different vendors. The goal is to provide an open source test suite to enable both open and closed source CNFs to demonstrate conformance and implementation of best practices."
task "all", ["all_prereqs", "configuration_file_setup", "compatibility","statelessness", "security", "scalability", "configuration_lifecycle", "observability", "installability", "hardware_affinity", "microservice", "resilience"] do  |_, args|
  LOGGING.info "all" if check_verbose(args)

  total = total_points
  if total > 0
    puts "Final score: #{total} of #{total_max_points}".colorize(:green)
  else
    puts "Final score: #{total} of #{total_max_points}".colorize(:red)
  end

  if failed_required_tasks.size > 0
    puts "Conformance Suite failed!".colorize(:red)
    puts "Failed required tasks: #{failed_required_tasks.inspect}".colorize(:red)
  end
  puts "Results have been saved to #{Results.file}"
end
# Git::CompileTimeVersionGenerater.tagged_version

task "version" do |_, args|
  LOGGING.info "VERSION: #{CnfConformance::VERSION}"
  puts CnfConformance::VERSION
end 


task "all_prereqs" do |_, args|
  LOGGING.info "all_prereqs" if check_verbose(args)
  check_cnf_config_then_deploy(args)
end

Sam.help
