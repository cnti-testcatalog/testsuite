require "sam"
require "./tasks/**"
require "./tasks/utils/utils.cr"
require "./tasks/utils/release_manager.cr"
require "./cnf_conformance.cr"


desc "The CNF Conformance program enables interoperability of CNFs from multiple vendors running on top of Kubernetes supplied by different vendors. The goal is to provide an open source test suite to enable both open and closed source CNFs to demonstrate conformance and implementation of best practices."
task "all", ["all_prereqs", "configuration_file_setup", "compatibility","statelessness", "security", "scalability", "configuration_lifecycle", "observability", "installability", "hardware_affinity", "microservice", "resilience"] do  |_, args|
  VERBOSE_LOGGING.info "all" if check_verbose(args)

  total = total_points
  if total > 0
    stdout_success "Final score: #{total} of #{total_max_points}"
  else
    stdout_failure "Final score: #{total} of #{total_max_points}"
  end

  if failed_required_tasks.size > 0
    stdout_failure "Conformance Suite failed!"
    stdout_failure "Failed required tasks: #{failed_required_tasks.inspect}"
  end
  stdout_info "Results have been saved to #{Results.file}".colorize(:green)
end

task "version" do |_, args|
  LOGGING.info "VERSION: #{CnfConformance::VERSION}"
  puts "CNF Conformance version: #{CnfConformance::VERSION}".colorize(:green)
end 

task "upsert_release" do |_, args|
  LOGGING.info "upserting release on: #{CnfConformance::VERSION}"
  release, asset = ReleaseManager::GithubReleaseManager.upsert_release
  if release
    puts "Created a release for: #{CnfConformance::VERSION}".colorize(:green) 
  else
    puts "Not creating a release for: #{CnfConformance::VERSION}".colorize(:red) 
  end
end

task "all_prereqs" do |_, args|
  VERBOSE_LOGGING.info "all_prereqs" if check_verbose(args)
  check_cnf_config_then_deploy(args)
end

task "test" do
  LOGGING.debug "debug test"
  LOGGING.info "info test"
  LOGGING.warn "warn test"
  LOGGING.error "error test"
  puts "ping"
end

# https://www.thegeekstuff.com/2013/12/bash-completion-complete/
# https://kubernetes.io/docs/tasks/tools/install-kubectl/#enable-kubectl-autocompletion
# https://stackoverflow.com/questions/43794270/disable-or-unset-specific-bash-completion
desc "Install Shell Completion: check https://github.com/cncf/cnf-conformance/blob/master/USAGE.md for usage"
task "completion" do |_|

# assumes bash completion feel free to make a pr for zsh and check an arg for it
bin_name = "cnf-conformance"

completion_template = <<-TEMPLATE
# to remove
# complete -r #{bin_name}
complete -W "#{Sam.root_namespace.all_tasks.map(&.name).join(" ")}" #{bin_name}
TEMPLATE

puts completion_template
end

Sam.help
