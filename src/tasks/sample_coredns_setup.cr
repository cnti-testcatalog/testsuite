require "sam"
require "file_utils"
require "colorize"
require "totem"
# require "commander"
require "./utils.cr"


desc "Sets up sample CoreDNS CNF"
task "sample_coredns_setup", ["helm_local_install"] do |_, args|
  current_dir = FileUtils.pwd 
  puts current_dir if check_verbose(args)

  # Retrieve the cnf source
  # TODO enable recloning/fetching etc
  git_clone = `git clone git@github.com:coredns/coredns.git #{current_dir}/#{CNF_DIR}/coredns`    
  puts git_clone if check_verbose(args)

  # Copy the cnf-conformance.yml
  yml_cp = `cp sample-cnfs/sample-coredns-cnf/cnf-conformance.yml #{current_dir}/#{CNF_DIR}/coredns`
  puts yml_cp if check_verbose(args)

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

  begin

    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    puts helm if check_verbose(args)
    helm_install = `#{helm} install coredns #{helm_chart}`
    puts helm_install if check_verbose(args)


    # Retrieve the helm chart source
    FileUtils.mkdir_p("#{current_dir}/#{CNF_DIR}/coredns/helm_chart") 
    helm_pull = `#{helm} pull #{helm_chart}`
    puts helm_pull if check_verbose(args)
    core_mv = `mv coredns-*.tgz #{current_dir}/#{CNF_DIR}/coredns/helm_chart`
    puts core_mv if check_verbose(args)
    tar = `cd #{current_dir}/#{CNF_DIR}/coredns/helm_chart; tar -xvf #{current_dir}/#{CNF_DIR}/coredns/helm_chart/coredns-*.tgz`
    puts tar if check_verbose(args)
    # coredns-coredns deployment must exist before running the next line (must already be installed)
    # # TODO get deployment name from previous install
    # manifest = `kubectl get deployment coredns-coredns -o yaml  > #{CNF_DIR}/coredns/helm_chart/coredns/manifest.yml`
    # puts manifest if check_verbose(args)
    if helm_install.to_s.size > 0 && helm_pull.to_s.size > 0
      puts "Successfully setup coredns".colorize(:green)
    end
  ensure
    cd = `cd #{current_dir}`
    puts cd if check_verbose(args)
  end
end

task "sample_coredns_cleanup" do |_, args|
  current_dir = FileUtils.pwd 
  helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
  puts helm if check_verbose(args)
  helm_uninstall = `#{helm} uninstall coredns`
  puts helm_uninstall if check_verbose(args)
  rm = `rm -rf #{current_dir}/#{CNF_DIR}/coredns`
  puts rm if check_verbose(args)
end
