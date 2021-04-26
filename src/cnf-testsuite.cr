require "sam"
require "./tasks/**"
require "./tasks/utils/utils.cr"
require "./tasks/utils/release_manager.cr"
require "./cnf_conformance.cr"


desc "The CNF Conformance program enables interoperability of CNFs from multiple vendors running on top of Kubernetes supplied by different vendors. The goal is to provide an open source test suite to enable both open and closed source CNFs to demonstrate conformance and implementation of best practices."
task "all", ["workload", "platform"] do  |_, args|
  VERBOSE_LOGGING.info "all" if check_verbose(args)

  total = CNFManager::Points.total_points
  if total > 0
    stdout_success "Final score: #{total} of #{CNFManager::Points.total_max_points}"
  else
    stdout_failure "Final score: #{total} of #{CNFManager::Points.total_max_points}"
  end

  if CNFManager::Points.failed_required_tasks.size > 0
    stdout_failure "Conformance Suite failed!"
    stdout_failure "Failed required tasks: #{CNFManager::Points.failed_required_tasks.inspect}"
  end
  stdout_info "CNFManager::Points::Results.have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
end

desc "The CNF Conformance program enables interoperability of CNFs from multiple vendors running on top of Kubernetes supplied by different vendors. The goal is to provide an open source test suite to enable both open and closed source CNFs to demonstrate conformance and implementation of best practices."
task "workload", ["automatic_cnf_install", "ensure_cnf_installed", "configuration_file_setup", "compatibility","statelessness", "security", "scalability", "configuration_lifecycle", "observability", "installability", "hardware_and_scheduling", "microservice", "resilience"] do  |_, args|
  VERBOSE_LOGGING.info "workload" if check_verbose(args)

  total = CNFManager::Points.total_points("workload")
  if total > 0
    stdout_success "Final workload score: #{total} of #{CNFManager::Points.total_max_points("workload")}"
  else
    stdout_failure "Final workload score: #{total} of #{CNFManager::Points.total_max_points("workload")}"
  end

  if CNFManager::Points.failed_required_tasks.size > 0
    stdout_failure "Conformance Suite failed!"
    stdout_failure "Failed required tasks: #{CNFManager::Points.failed_required_tasks.inspect}"
  end
  stdout_info "CNFManager::Points::Results.have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
end

desc "Makes sure a cnf is in the cnf directory"
task "ensure_cnf_installed" do |_, args|
  unless CNFManager.cnf_installed?
    puts "You must install a CNF first.".colorize(:yellow)
    exit 1
  end
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

task "automatic_cnf_install" do |_, args|
  VERBOSE_LOGGING.info "all_prereqs" if check_verbose(args)
  # check_cnf_config_then_deploy(args)
  cli_hash = CNFManager.sample_setup_cli_args(args, false)
  CNFManager.sample_setup(cli_hash) if !cli_hash["config_file"].empty?
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
desc "Install Shell Completion: check https://github.com/cncf/cnf-conformance/blob/main/USAGE.md for usage"
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

# Sam.help
begin
  puts `./cnf-conformance help` if ARGV.empty?
  # See issue #426 for exit code requirement
  Sam.process_tasks(ARGV.clone) 
  yaml = File.open("#{CNFManager::Points::Results.file}") do |file|
    YAML.parse(file)
  end
  LOGGING.debug "results yaml: #{yaml}"
  if (yaml["exit_code"]) == 1
    exit 1
  end
rescue e : Sam::NotFound
  puts e.message
  exit 1
rescue e
  puts e.backtrace.join("\n"), e
  exit 1
end
