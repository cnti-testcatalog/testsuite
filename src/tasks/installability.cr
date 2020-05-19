require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "The CNF conformance suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s kubectl"
task "installability", ["install_script_helm", "helm_chart_valid", "helm_chart_published", "helm_deploy"] do |_, args|
end

desc "Will the CNF install using helm with helm_deploy?"
task "helm_deploy" do |_, args|
  begin
    puts "helm_deploy" if check_verbose(args)
    config = get_parsed_cnf_conformance_yml(args)

    helm_chart = "#{config.get("helm_chart").as_s?}"
    helm_directory = "#{config.get("helm_directory").as_s?}"
    release_name = "#{config.get("release_name").as_s?}"

    current_dir = FileUtils.pwd
    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    puts helm if check_verbose(args)

    create_namespace = `kubectl create namespace helm-deploy-test`
    if helm_chart.empty? 
    #TODO make this work off of a helm directory if helm_directory was passed
    yml_file_path = cnf_conformance_yml_file_path(args)
    puts "helm_directory: #{helm_directory}" if check_verbose(args)
    puts "yaml_path: #{yml_file_path}" if check_verbose(args)
    helm_install = `#{helm} install --namespace helm-deploy-test #{release_name} #{yml_file_path}/#{helm_directory}`
    else 
    puts "helm_chart: #{helm_chart}" if check_verbose(args)
    helm_install = `#{helm} install --namespace helm-deploy-test #{release_name} #{helm_chart}`
    end 

    is_helm_installed = $?.success?
    puts helm_install if check_verbose(args)

    if is_helm_installed
      upsert_passed_task("helm_deploy")
      puts "PASSED: Helm deploy successful".colorize(:green)
    else
      upsert_failed_task("helm_deploy")
      puts "FAILURE: Helm deploy failed".colorize(:red)
    end
    
    delete_namespace = `kubectl delete namespace helm-deploy-test --force --grace-period 0`

  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end

desc "Does the install script use helm?"
task "install_script_helm" do |_, args|
  begin
    # Parse the cnf-conformance.yml
    config = cnf_conformance_yml

    found = 0
    current_cnf_dir_short_name = cnf_conformance_dir
    puts current_cnf_dir_short_name if check_verbose(args)
    destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    puts destination_cnf_dir if check_verbose(args)
    install_script = config.get("install_script").as_s?
    if install_script
    response = String::Builder.new
    content = File.open("#{destination_cnf_dir}/#{install_script}") do |file|
      file.gets_to_end
    end
    # puts content
    if /helm/ =~ content 
      found = 1
    end
    if found < 1
      upsert_failed_task("install_script_helm")
      puts "FAILURE: Helm not found in supplied install script".colorize(:red)
    else
      upsert_passed_task("install_script_helm")
      puts "PASSED: Helm found in supplied install script".colorize(:green)
    end
    else
      upsert_passed_task("install_script_helm")
      puts "PASSED (by default): No install script provided".colorize(:green)
    end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end

task "helm_chart_published", ["helm_local_install"] do |_, args|
  begin
    puts "helm_chart_published" if check_verbose(args)
    puts "helm_chart_published args.raw: #{args.raw}" if check_verbose(args)
    puts "helm_chart_published args.named: #{args.named}" if check_verbose(args)

    config = cnf_conformance_yml
    helm_chart = "#{config.get("helm_chart").as_s?}"
    helm_directory = "#{config.get("helm_directory").as_s?}"

    current_dir = FileUtils.pwd 
    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    puts helm if check_verbose(args)

   if helm_repo_add
     unless helm_chart.empty?
       helm_search = `#{helm} search repo #{helm_chart}`
       puts "#{helm_search}" if check_verbose(args)
       unless helm_search =~ /No results found/
         upsert_passed_task("helm_chart_published")
         puts "PASSED: Published Helm Chart Found".colorize(:green)
       else
         upsert_failed_task("helm_chart_published")
         puts "FAILURE: Published Helm Chart Not Found".colorize(:red)
       end
     else
       upsert_failed_task("helm_chart_published")
       puts "FAILURE: Published Helm Chart Not Found".colorize(:red)
     end
   else
     upsert_failed_task("helm_chart_published")
     puts "FAILURE: Published Helm Chart Not Found".colorize(:red)
   end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
 puts x
    end
  end
end

task "helm_chart_valid", ["helm_local_install"] do |_, args|
  begin
    puts "helm_chart_valid args.raw: #{args.raw}" if check_verbose(args)
    puts "helm_chart_valid args.named: #{args.named}" if check_verbose(args)

    response = String::Builder.new

    config = cnf_conformance_yml
    helm_directory = config.get("helm_directory").as_s
    # helm_chart_repo = config.get("helm_chart").as_s

    if args.named.keys.includes? "cnf_chart_path"
      helm_directory = args.named["cnf_chart_path"]
    end

    puts "helm_directory: #{helm_directory}" if check_verbose(args)
    # puts "helm_chart_repo: #{helm_chart_repo}" if check_verbose(args)

    current_dir = FileUtils.pwd 
    puts current_dir if check_verbose(args)
    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"

    current_cnf_dir_short_name = cnf_conformance_dir
    puts current_cnf_dir_short_name if check_verbose(args)
    destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    puts destination_cnf_dir if check_verbose(args)
    ls_helm_directory = `ls -al #{destination_cnf_dir}/#{helm_directory}`
    puts "ls -al of helm_directory: #{ls_helm_directory}" if check_verbose(args)

    helm_lint = `#{helm} lint #{destination_cnf_dir}/#{helm_directory}`
    puts "helm_lint: #{helm_lint}" if check_verbose(args)

    # Process.run("helm lint #{helm_directory}", shell: true) do |proc|
    #   while line = proc.output.gets
    #     response << line
    #     puts "#{line}" if check_verbose(args)
    #   end
    # end

   if $?.success? 
     upsert_passed_task("helm_chart_valid")
     puts "PASSED: Helm Chart #{helm_directory} Lint Passed".colorize(:green)
   else
     upsert_failed_task("helm_chart_valid")
     puts "FAILURE: Helm Chart #{helm_directory} Lint Failed".colorize(:red)
   end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end

