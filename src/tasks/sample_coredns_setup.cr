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
  puts "sample_coredns new setup" if check_verbose(args)
  sample_setup_args(sample_dir: "sample-cnfs/sample_coredns", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
end

desc "Sets up a Bad helm CNF Setup"
task "bad_helm_cnf_setup", ["helm_local_install"] do |_, args|
  puts "bad_helm_cnf_setup" if check_verbose(args)
  sample_setup_args(sample_dir: "sample-cnfs/sample-bad_helm_coredns-cnf", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
end

task "sample_privileged_cnf_whitelisted_setup", ["helm_local_install"] do |_, args|
  puts "sample_privileged_cnf_whitelisted_setup" if check_verbose(args)
  sample_setup_args(sample_dir: "sample-cnfs/sample_whitelisted_privileged_cnf", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
end

task "sample_privileged_cnf_non_whitelisted_setup", ["helm_local_install"] do |_, args|
  puts "sample_privileged_cnf_non_whitelisted_setup" if check_verbose(args)
  sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
end

task "sample_coredns_bad_liveness", ["helm_local_install"] do |_, args|
  puts "sample_coredns_bad_liveness" if check_verbose(args)
    sample_setup_args(sample_dir: "sample-cnfs/sample_coredns_bad_liveness", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
end

task "sample_generic_cnf_setup", ["helm_local_install"] do |_, args|
  puts "sample_generic_cnf" if check_verbose(args)
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", deploy_with_chart: false, args: args, verbose: true )
end

task "example_cnf_setup", ["helm_local_install"] do |_, args|
  puts "sample_generic_cnf" if check_verbose(args)
  example_cnf = args.named["example-cnf-path"].as(String)
  sample_setup_args(sample_dir: example_cnf, deploy_with_chart: true, args: args, verbose: true )
end

task "example_cnf_cleanup" do |_, args|
  example_cnf = args.named["example-cnf-path"].as(String)
  sample_cleanup(sample_dir: example_cnf, verbose: true)
end

task "sample_coredns_cleanup" do |_, args|
  sample_cleanup(sample_dir: "sample-cnfs/sample-coredns-cnf", verbose: true)
end

task "cleanup_sample_coredns" do |_, args|
  sample_cleanup(sample_dir: "sample-cnfs/sample_coredns", verbose: true)
end

task "bad_helm_cnf_cleanup" do |_, args|
  sample_cleanup(sample_dir: "sample-cnfs/sample-bad_helm_coredns-cnf", verbose: true)
end

task "sample_privileged_cnf_whitelisted_cleanup" do |_, args|
  sample_cleanup(sample_dir: "sample-cnfs/sample_whitelisted_privileged_cnf", verbose: true)
end

task "sample_privileged_cnf_non_whitelisted_cleanup" do |_, args|
  sample_cleanup(sample_dir: "sample-cnfs/sample_privileged_cnf", verbose: true)
end

task "sample_coredns_bad_liveness_cleanup" do |_, args|
  sample_cleanup(sample_dir: "sample-cnfs/sample_coredns_bad_liveness", verbose: true)
end
task "sample_coredns_source_cleanup" do |_, args|
  sample_cleanup(sample_dir: "sample-cnfs/sample-coredns-cnf-source", verbose: true)
end

task "sample_generic_cnf_cleanup" do |_, args|
  sample_cleanup(sample_dir: "sample-cnfs/sample-generic-cnf", verbose: true)
end
