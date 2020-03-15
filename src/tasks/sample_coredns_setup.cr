require "sam"
require "file_utils"
require "colorize"
require "totem"
# require "commander"
require "./utils.cr"


desc "Sets up sample CoreDNS CNF"
task "sample_coredns_setup", ["helm_local_install"] do |_, args|
    sample_setup_args(sample_dir: "sample-cnfs/sample-coredns-cnf", args: args, verbose: true )
end

desc "Sets up sample CoreDNS CNF with source"
task "sample_coredns_source_setup", ["helm_local_install"] do |_, args|
    sample_setup_args(sample_dir: "sample-cnfs/sample-coredns-cnf-source", args: args, verbose: true )
end

desc "Sets up an alternate sample CoreDNS CNF"
task "sample_coredns", ["helm_local_install"] do |_, args|
  puts "sample_coredns new setup" if check_verbose(args)
  sample_setup_args(sample_dir: "sample-cnfs/sample_coredns", deploy_with_chart: false, args: args, verbose: true )
end


desc "Sets up a Bad helm CNF Setup"
task "bad_helm_cnf_setup", ["helm_local_install"] do |_, args|
  puts "bad_helm_cnf_setup" if check_verbose(args)
  sample_setup_args(sample_dir: "sample-cnfs/sample-bad_helm_coredns-cnf", deploy_with_chart: false, args: args, verbose: true, wait_count: 5 )
end

task "sample_privileged_cnf_whitelisted_setup", ["helm_local_install"] do |_, args|
  current_dir = FileUtils.pwd 
  puts current_dir if check_verbose(args)

  # Copy the chart into the cnfs directory and use the correct cnf-conformance.yml
  chart_cp = `cp -r #{current_dir}/sample-cnfs/sample_privileged_cnf_setup_coredns #{current_dir}/#{CNF_DIR}/`
  yml_mv = `mv #{current_dir}/#{CNF_DIR}/sample_privileged_cnf_setup_coredns/whitelisted-conformance.yml #{current_dir}/#{CNF_DIR}/sample_privileged_cnf_setup_coredns/cnf-conformance.yml`
  puts chart_cp if check_verbose(args)
  puts yml_mv if check_verbose(args)

  # Parse the cnf-conformance.yml
  config = cnf_conformance_yml

  if args.named.keys.includes? "deployment_name"
    deployment_name = args.named["deployment_name"]
  else
    deployment_name = config.get("deployment_name").as_s 
  end
  puts "deployment_name: #{deployment_name}" if check_verbose(args)

  if args.named.keys.includes? "helm_chart"
    helm_chart = args.named["helm_chart"]
  else
    helm_chart = config.get("helm_chart").as_s 
  end
  puts "helm_chart: #{helm_chart}" if check_verbose(args)

  if args.named.keys.includes? "helm_directory"
    helm_directory = args.named["helm_directory"]
  else
    helm_directory = config.get("helm_directory").as_s 
  end
  puts "helm_directory: #{helm_directory}" if check_verbose(args)

  begin

    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    puts helm if check_verbose(args)
    helm_install = `#{helm} install privileged-coredns #{helm_directory}`
    puts helm_install if check_verbose(args)

    wait_for_install(deployment_name)
    if helm_install.to_s.size > 0
      puts "Successfully setup sample_privileged_cnf_whitelisted_setup".colorize(:green)
    end
  ensure
    cd = `cd #{current_dir}`
    puts cd if check_verbose(args)
  end
end


task "sample_privileged_cnf_non_whitelisted_setup", ["helm_local_install"] do |_, args|
  current_dir = FileUtils.pwd 
  puts current_dir if check_verbose(args)

  # Copy the chart into the cnfs directory and use the correct cnf-conformance.yml
  chart_cp = `cp -r #{current_dir}/sample-cnfs/sample_privileged_cnf_setup_coredns #{current_dir}/#{CNF_DIR}/`
  yml_mv = `mv #{current_dir}/#{CNF_DIR}/sample_privileged_cnf_setup_coredns/non-whitelisted-conformance.yml #{current_dir}/#{CNF_DIR}/sample_privileged_cnf_setup_coredns/cnf-conformance.yml`
  puts chart_cp if check_verbose(args)
  puts yml_mv if check_verbose(args)

  # Parse the cnf-conformance.yml
  config = cnf_conformance_yml

  if args.named.keys.includes? "deployment_name"
    deployment_name = args.named["deployment_name"]
  else
    deployment_name = config.get("deployment_name").as_s 
  end
  puts "deployment_name: #{deployment_name}" if check_verbose(args)

  if args.named.keys.includes? "helm_chart"
    helm_chart = args.named["helm_chart"]
  else
    helm_chart = config.get("helm_chart").as_s 
  end
  puts "helm_chart: #{helm_chart}" if check_verbose(args)

  if args.named.keys.includes? "helm_directory"
    helm_directory = args.named["helm_directory"]
  else
    helm_directory = config.get("helm_directory").as_s 
  end
  puts "helm_directory: #{helm_directory}" if check_verbose(args)

  begin

    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    puts helm if check_verbose(args)
    helm_install = `#{helm} install privileged-coredns #{helm_directory}`
    puts helm_install if check_verbose(args)

    wait_for_install(deployment_name)
    if helm_install.to_s.size > 0
      puts "Successfully setup sample_privileged_cnf_non_whitelisted_setup".colorize(:green)
    end
  ensure
    cd = `cd #{current_dir}`
    puts cd if check_verbose(args)
  end
end

task "sample_coredns_bad_liveness", ["helm_local_install"] do |_, args|
  puts "sample_coredns_bad_liveness" if check_verbose(args)
    sample_setup_args(sample_dir: "sample-cnfs/sample_coredns_bad_liveness", deploy_with_chart: false, args: args, verbose: true )
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
  current_dir = FileUtils.pwd 
  helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
  puts helm if check_verbose(args)
  helm_uninstall = `#{helm} uninstall privileged-coredns`
  puts helm_uninstall if check_verbose(args)
  rm = `rm -rf #{current_dir}/#{CNF_DIR}/sample_privileged_cnf_setup_coredns`
  puts rm if check_verbose(args)
end

task "sample_privileged_cnf_non_whitelisted_cleanup" do |_, args|
  current_dir = FileUtils.pwd 
  helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
  puts helm if check_verbose(args)
  helm_uninstall = `#{helm} uninstall privileged-coredns`
  puts helm_uninstall if check_verbose(args)
  rm = `rm -rf #{current_dir}/#{CNF_DIR}/sample_privileged_cnf_setup_coredns`
  puts rm if check_verbose(args)
end

task "sample_coredns_bad_liveness_cleanup" do |_, args|
  sample_cleanup(sample_dir: "sample-cnfs/sample_coredns_bad_liveness", verbose: true)
end
task "sample_coredns_source_cleanup" do |_, args|
  sample_cleanup(sample_dir: "sample-cnfs/sample-coredns-cnf-source", verbose: true)
end

