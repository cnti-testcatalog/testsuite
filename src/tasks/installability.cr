# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "The CNF conformance suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s kubectl"
task "installability", ["install_script_helm", "helm_chart_valid", "helm_chart_published", "helm_deploy"] do |_, args|
  total = total_points("installability")
  if total > 0
    puts "Installability final score: #{total} of #{total_max_points("installability")}".colorize(:green)
  else
    puts "Installability final score: #{total} of #{total_max_points("installability")}".colorize(:red)
  end
end

desc "Will the CNF install using helm with helm_deploy?"
task "helm_deploy" do |_, args|
  LOGGING.info "helm_deploy" if check_verbose(args)
  LOGGING.info("helm_deploy args: #{args.inspect}")
  if check_cnf_config(args) || destination_cnfs_exist?
    task_runner(args) do |args|
      begin
        release_name_prefix = "helm-deploy-"
        config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))

        helm_chart = "#{config.get("helm_chart").as_s?}"
        helm_directory = "#{config.get("helm_directory").as_s?}"
        release_name = "#{config.get("release_name").as_s?}"

        current_dir = FileUtils.pwd
        helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
        LOGGING.debug helm if check_verbose(args)

        if helm_chart.empty? 
          #TODO make this work off of a helm directory if helm_directory was passed
          # yml_file_path = cnf_conformance_yml_file_path(args)
          yml_file_path = ensure_cnf_conformance_dir(args.named["cnf-config"].as(String))
          LOGGING.debug "#{helm} install #{release_name_prefix}#{release_name} #{yml_file_path}/#{helm_directory}" if check_verbose(args)
          helm_install = `#{helm} install #{release_name_prefix}#{release_name} #{yml_file_path}/#{helm_directory}`
        else 
          LOGGING.debug "#{helm} install #{release_name_prefix}#{release_name} #{helm_chart}" if check_verbose(args)
          helm_install = `#{helm} install #{release_name_prefix}#{release_name} #{helm_chart}`
        end

        is_helm_installed = $?.success?
        LOGGING.info helm_install if check_verbose(args)

        if is_helm_installed
          upsert_passed_task("helm_deploy")
          puts "✔️  PASSED: Helm deploy successful".colorize(:green)
        else
          upsert_failed_task("helm_deploy")
          puts "✖️  FAILURE: Helm deploy failed".colorize(:red)
        end
      ensure
        LOGGING.debug "#{helm} uninstall #{release_name_prefix}#{release_name}" if check_verbose(args)
        helm_uninstall = `#{helm} uninstall #{release_name_prefix}#{release_name}`
      end
    end
  else
    upsert_failed_task("helm_deploy", "✖️  FAILURE: No cnf_conformance.yml found! Did you run the setup task?")
  end
end

desc "Does the install script use helm?"
task "install_script_helm" do |_, args|
  task_runner(args) do |args|
    # Parse the cnf-conformance.yml
    # config = cnf_conformance_yml
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))

    found = 0
    # current_cnf_dir_short_name = cnf_conformance_dir
    # current_cnf_dir_short_name = ensure_cnf_conformance_dir(args.named["cnf-config"].as(String))
    # puts current_cnf_dir_short_name if check_verbose(args)
    # destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    destination_cnf_dir = cnf_destination_dir(ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    LOGGING.debug destination_cnf_dir if check_verbose(args)
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
        puts "✖️  FAILURE: Helm not found in supplied install script".colorize(:red)
      else
        upsert_passed_task("install_script_helm")
        puts "✔️  PASSED: Helm found in supplied install script".colorize(:green)
      end
    else
      upsert_passed_task("install_script_helm")
      puts "PASSED (by default): No install script provided".colorize(:green)
    end
  end
end

task "helm_chart_published", ["helm_local_install"] do |_, args|
  task_runner(args) do |args|
    LOGGING.info "helm_chart_published" if check_verbose(args)
    LOGGING.debug "helm_chart_published args.raw: #{args.raw}" if check_verbose(args)
    LOGGING.debug "helm_chart_published args.named: #{args.named}" if check_verbose(args)

    # config = cnf_conformance_yml
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    helm_chart = "#{config.get("helm_chart").as_s?}"
    helm_directory = "#{config.get("helm_directory").as_s?}"

    current_dir = FileUtils.pwd 
    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    LOGGING.debug helm if check_verbose(args)

    if helm_repo_add(args: args)
      unless helm_chart.empty?
        helm_search = `#{helm} search repo #{helm_chart}`
        LOGGING.debug "#{helm_search}" if check_verbose(args)
        unless helm_search =~ /No results found/
          upsert_passed_task("helm_chart_published")
          puts "✔️  PASSED: Published Helm Chart Found".colorize(:green)
        else
          upsert_failed_task("helm_chart_published")
          puts "✖️  FAILURE: Published Helm Chart Not Found".colorize(:red)
        end
      else
        upsert_failed_task("helm_chart_published")
        puts "✖️  FAILURE: Published Helm Chart Not Found".colorize(:red)
      end
    else
      upsert_failed_task("helm_chart_published")
      puts "✖️  FAILURE: Published Helm Chart Not Found".colorize(:red)
    end
  end
end

task "helm_chart_valid", ["helm_local_install"] do |_, args|
  task_runner(args) do |args|
    LOGGING.info "helm_chart_valid" if check_verbose(args)
    LOGGING.debug "helm_chart_valid args.raw: #{args.raw}" if check_verbose(args)
    LOGGING.debug "helm_chart_valid args.named: #{args.named}" if check_verbose(args)

    response = String::Builder.new

    # config = cnf_conformance_yml
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    helm_directory = config.get("helm_directory").as_s
    # helm_chart_repo = config.get("helm_chart").as_s

    if args.named.keys.includes? "cnf_chart_path"
      helm_directory = args.named["cnf_chart_path"]
    end

    LOGGING.debug "helm_directory: #{helm_directory}" if check_verbose(args)
    # puts "helm_chart_repo: #{helm_chart_repo}" if check_verbose(args)

    current_dir = FileUtils.pwd 
    LOGGING.debug current_dir if check_verbose(args)
    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"

    # current_cnf_dir_short_name = cnf_conformance_dir
    # puts current_cnf_dir_short_name if check_verbose(args)
    # destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    # puts destination_cnf_dir if check_verbose(args)
    destination_cnf_dir = cnf_destination_dir(ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    ls_helm_directory = `ls -al #{destination_cnf_dir}/#{helm_directory}`
    LOGGING.debug "ls -al of helm_directory: #{ls_helm_directory}" if check_verbose(args)

    helm_lint = `#{helm} lint #{destination_cnf_dir}/#{helm_directory}`
    LOGGING.debug "helm_lint: #{helm_lint}" if check_verbose(args)

    if $?.success? 
      upsert_passed_task("helm_chart_valid")
      puts "✔️  PASSED: Helm Chart #{helm_directory} Lint Passed".colorize(:green)
    else
      upsert_failed_task("helm_chart_valid")
      puts "✖️  FAILURE: Helm Chart #{helm_directory} Lint Failed".colorize(:red)
    end
  end
end

task "validate_config" do |_, args|
  yml = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
  valid, warning_output = validate_cnf_conformance_yml(yml)

  if valid
    puts "✔️ PASSED: CNF configuration validated 📋".colorize(:green)
  else
    puts "❌ FAILURE: Critical Error with CNF Configuration. Please review USAGE.md for steps to set up a valid CNF configuration file 📋".colorize(:red)
  end
end
