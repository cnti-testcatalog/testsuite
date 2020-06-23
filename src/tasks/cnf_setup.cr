require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Sets up sample CoreDNS CNF"
task "sample_coredns_setup", ["helm_local_install"] do |_, args|
  sample_setup_args(sample_dir: "sample-cnfs/sample-coredns-cnf", args: args, verbose: true, wait_count: 0 )
end

task "sample_coredns_with_wait_setup", ["helm_local_install"] do |_, args|
  sample_setup_args(sample_dir: "sample-cnfs/sample-coredns-cnf", args: args, verbose: true)
end

desc "Sets up sample CoreDNS CNF with source"
task "sample_coredns_source_setup", ["helm_local_install"] do |_, args|
  sample_setup_args(sample_dir: "sample-cnfs/sample-coredns-cnf-source", args: args, verbose: true, wait_count: 0 )
end

desc "Sets up an alternate sample CoreDNS CNF"
task "sample_coredns", ["helm_local_install"] do |_, args|
  LOGGING.info "sample_coredns new setup" if check_verbose(args)
  sample_setup_args(sample_dir: "sample-cnfs/sample_coredns", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
end

desc "Sets up a Bad helm CNF Setup"
task "bad_helm_cnf_setup", ["helm_local_install"] do |_, args|
  LOGGING.info "bad_helm_cnf_setup" if check_verbose(args)
  sample_setup_args(sample_dir: "sample-cnfs/sample-bad_helm_coredns-cnf", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
end

task "sample_privileged_cnf_whitelisted_setup", ["helm_local_install"] do |_, args|
  LOGGING.info "sample_privileged_cnf_whitelisted_setup" if check_verbose(args)
  sample_setup_args(sample_dir: "sample-cnfs/sample_whitelisted_privileged_cnf", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
end

task "sample_privileged_cnf_non_whitelisted_setup", ["helm_local_install"] do |_, args|
  LOGGING.info "sample_privileged_cnf_non_whitelisted_setup" if check_verbose(args)
  sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
end

task "sample_coredns_bad_liveness", ["helm_local_install"] do |_, args|
  LOGGING.info "sample_coredns_bad_liveness" if check_verbose(args)
  sample_setup_args(sample_dir: "sample-cnfs/sample_coredns_bad_liveness", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
end

task "sample_generic_cnf_setup", ["helm_local_install"] do |_, args|
  LOGGING.info "sample_generic_cnf" if check_verbose(args)
  sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", deploy_with_chart: false, args: args, verbose: true )
end

task "cnf_setup", ["helm_local_install"] do |_, args|
  LOGGING.info "cnf_setup" if check_verbose(args)
  LOGGING.debug "args = #{args.inspect}" if check_verbose(args)
  if args.named.keys.includes? "cnf-config"
    yml_file = args.named["cnf-config"].as(String)
    # example_cnf = File.dirname(File.expand_path(yml_file))
    cnf = File.dirname(yml_file)
  elsif args.named.keys.includes? "cnf-path"
    cnf = args.named["cnf-path"].as(String)
  else
    puts "Error: You must supply either cnf-config or cnf-path".colorize(:red)
    exit 1
	end
  LOGGING.info "cnf_setup cnf: #{cnf}" if check_verbose(args)
  if args.named["deploy_with_chart"]? && args.named["deploy_with_chart"] == "false"
    deploy_with_chart = false
  else
    deploy_with_chart = true
  end
  sample_setup_args(sample_dir: cnf, deploy_with_chart: deploy_with_chart, args: args, verbose: check_verbose(args) )
end

task "cnf_cleanup" do |_, args|
  LOGGING.info "cnf_cleanup" if check_verbose(args)
  LOGGING.debug "args = #{args.inspect}" if check_verbose(args)
  if args.named.keys.includes? "cnf-config"
    yml_file = args.named["cnf-config"].as(String)
    cnf = File.dirname(yml_file)
  elsif args.named.keys.includes? "cnf-path"
    cnf = args.named["cnf-path"].as(String)
  else
    puts "Error: You must supply either cnf-config or cnf-path".colorize(:red)
    exit 1
	end
  LOGGING.debug "cnf_cleanup cnf: #{cnf}" if check_verbose(args)
  if args.named["force"]? && args.named["force"] == "true"
    force = true 
  else
    force = false
  end
  sample_cleanup(config_file: cnf, force: force, verbose: check_verbose(args))
end

task "helm_repo_add" do |_, args|
  LOGGING.info "helm_repo_add" if check_verbose(args)
  LOGGING.debug "args = #{args.inspect}" if check_verbose(args)
  if args.named["cnf-config"]? || args.named["yml-file"]?
    helm_repo_add(args: args)
  else
    helm_repo_add
  end

end

task "sample_coredns_cleanup" do |_, args|
  sample_cleanup(config_file: "sample-cnfs/sample-coredns-cnf", verbose: true)
end

task "cleanup_sample_coredns" do |_, args|
  sample_cleanup(config_file: "sample-cnfs/sample_coredns", verbose: true)
end

task "bad_helm_cnf_cleanup" do |_, args|
  sample_cleanup(config_file: "sample-cnfs/sample-bad_helm_coredns-cnf", verbose: true)
end

task "sample_privileged_cnf_whitelisted_cleanup" do |_, args|
  sample_cleanup(config_file: "sample-cnfs/sample_whitelisted_privileged_cnf", verbose: true)
end

task "sample_privileged_cnf_non_whitelisted_cleanup" do |_, args|
  sample_cleanup(config_file: "sample-cnfs/sample_privileged_cnf", verbose: true)
end

task "sample_coredns_bad_liveness_cleanup" do |_, args|
  sample_cleanup(config_file: "sample-cnfs/sample_coredns_bad_liveness", verbose: true)
end
task "sample_coredns_source_cleanup" do |_, args|
  sample_cleanup(config_file: "sample-cnfs/sample-coredns-cnf-source", verbose: true)
end

task "sample_generic_cnf_cleanup" do |_, args|
  sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
end
