require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

task "cnf_setup", ["helm_local_install"] do |_, args|
  VERBOSE_LOGGING.info "cnf_setup" if check_verbose(args)
  VERBOSE_LOGGING.debug "args = #{args.inspect}" if check_verbose(args)
  cli_hash = CNFManager.sample_setup_cli_args(args)
  CNFManager.sample_setup(cli_hash)
end

task "cnf_cleanup" do |_, args|
  VERBOSE_LOGGING.info "cnf_cleanup" if check_verbose(args)
  VERBOSE_LOGGING.debug "args = #{args.inspect}" if check_verbose(args)
  if args.named.keys.includes? "cnf-config"
    yml_file = args.named["cnf-config"].as(String)
    cnf = File.dirname(yml_file)
  elsif args.named.keys.includes? "cnf-path"
    cnf = args.named["cnf-path"].as(String)
  else
    stdout_failure "Error: You must supply either cnf-config or cnf-path"
    exit 1
	end
  VERBOSE_LOGGING.debug "cnf_cleanup cnf: #{cnf}" if check_verbose(args)
  if args.named["force"]? && args.named["force"] == "true"
    force = true 
  else
    force = false
  end
  CNFManager.sample_cleanup(config_file: cnf, force: force, verbose: check_verbose(args))
end

task "CNFManager.helm_repo_add" do |_, args|
  VERBOSE_LOGGING.info "CNFManager.helm_repo_add" if check_verbose(args)
  VERBOSE_LOGGING.debug "args = #{args.inspect}" if check_verbose(args)
  if args.named["cnf-config"]? || args.named["yml-file"]?
    CNFManager.helm_repo_add(args: args)
  else
    CNFManager.helm_repo_add
  end

end

#TODO force all cleanups to use generic cleanup
task "sample_coredns_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-coredns-cnf", verbose: true)
end

task "cleanup_sample_coredns" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample_coredns", verbose: true)
end

task "bad_helm_cnf_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-bad_helm_coredns-cnf", verbose: true)
end

task "sample_privileged_cnf_whitelisted_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample_whitelisted_privileged_cnf", verbose: true)
end

task "sample_privileged_cnf_non_whitelisted_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample_privileged_cnf", verbose: true)
end

task "sample_coredns_bad_liveness_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample_coredns_bad_liveness", verbose: true)
end
task "sample_coredns_source_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-coredns-cnf-source", verbose: true)
end

task "sample_generic_cnf_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
end
