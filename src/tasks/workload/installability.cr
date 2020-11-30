# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "The CNF conformance suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s kubectl"
task "installability", ["install_script_helm", "helm_chart_valid", "helm_chart_published", "helm_deploy"] do |_, args|
  stdout_score("installability")
end

desc "Will the CNF install using helm with helm_deploy?"
task "helm_deploy" do |_, args|
  VERBOSE_LOGGING.info "helm_deploy" if check_verbose(args)
  LOGGING.info("helm_deploy args: #{args.inspect}")
  if check_cnf_config(args) || CNFManager.destination_cnfs_exist?
    task_runner(args) do |args|
      begin
        release_name_prefix = "helm-deploy-"
        config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))

        helm_chart = "#{config.get("helm_chart").as_s?}"
        helm_directory = "#{config.get("helm_directory").as_s?}"
        release_name = "#{config.get("release_name").as_s?}"

        current_dir = FileUtils.pwd
        #helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    helm = CNFSingleton.helm
        VERBOSE_LOGGING.debug helm if check_verbose(args)

        if helm_chart.empty? 
          #TODO make this work off of a helm directory if helm_directory was passed
          # yml_file_path = cnf_conformance_yml_file_path(args)
          yml_file_path = CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String))
          VERBOSE_LOGGING.debug "#{helm} install #{release_name_prefix}#{release_name} #{yml_file_path}/#{helm_directory}" if check_verbose(args)
          helm_install = `#{helm} install #{release_name_prefix}#{release_name} #{yml_file_path}/#{helm_directory}`
        else 
          VERBOSE_LOGGING.debug "#{helm} install #{release_name_prefix}#{release_name} #{helm_chart}" if check_verbose(args)
          helm_install = `#{helm} install #{release_name_prefix}#{release_name} #{helm_chart}`
        end

        is_helm_installed = $?.success?
        VERBOSE_LOGGING.info helm_install if check_verbose(args)

        if is_helm_installed
          upsert_passed_task("helm_deploy", "✔️  PASSED: Helm deploy successful")
        else
          upsert_failed_task("helm_deploy", "✖️  FAILURE: Helm deploy failed")
        end
      ensure
        VERBOSE_LOGGING.debug "#{helm} uninstall #{release_name_prefix}#{release_name}" if check_verbose(args)
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
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))

    found = 0
    # current_cnf_dir_short_name = CNFManager.ensure_cnf_conformance_dir
    # current_cnf_dir_short_name = CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String))
    # VERBOSE_LOGGING.debug current_cnf_dir_short_name if check_verbose(args)
    # destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    VERBOSE_LOGGING.debug destination_cnf_dir if check_verbose(args)
    install_script = config.get("install_script").as_s?
    if install_script
      response = String::Builder.new
      content = File.open("#{destination_cnf_dir}/#{install_script}") do |file|
        file.gets_to_end
      end
      # LOGGING.debug content
      if /helm/ =~ content 
        found = 1
      end
      if found < 1
        upsert_failed_task("install_script_helm", "✖️  FAILURE: Helm not found in supplied install script")
      else
        upsert_passed_task("install_script_helm", "✔️  PASSED: Helm found in supplied install script")
      end
    else
      upsert_passed_task("install_script_helm", "✔️  PASSED (by default): No install script provided")
    end
  end
end

task "helm_chart_published", ["helm_local_install"] do |_, args|
  task_runner(args) do |args|
    VERBOSE_LOGGING.info "helm_chart_published" if check_verbose(args)
    VERBOSE_LOGGING.debug "helm_chart_published args.raw: #{args.raw}" if check_verbose(args)
    VERBOSE_LOGGING.debug "helm_chart_published args.named: #{args.named}" if check_verbose(args)

    # config = cnf_conformance_yml
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    helm_chart = "#{config.get("helm_chart").as_s?}"
    helm_directory = "#{config.get("helm_directory").as_s?}"

    current_dir = FileUtils.pwd 
    #helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    helm = CNFSingleton.helm
    VERBOSE_LOGGING.debug helm if check_verbose(args)

    if CNFManager.helm_repo_add(args: args)
      unless helm_chart.empty?
        helm_search = `#{helm} search repo #{helm_chart}`
        LOGGING.info "helm search command: #{helm} search repo #{helm_chart}"
        VERBOSE_LOGGING.debug "#{helm_search}" if check_verbose(args)
        unless helm_search =~ /No results found/
          upsert_passed_task("helm_chart_published", "✔️  PASSED: Published Helm Chart Found")
        else
          upsert_failed_task("helm_chart_published", "✖️  FAILURE: Published Helm Chart Not Found")
        end
      else
        upsert_failed_task("helm_chart_published", "✖️  FAILURE: Published Helm Chart Not Found")
      end
    else
      upsert_failed_task("helm_chart_published", "✖️  FAILURE: Published Helm Chart Not Found")
    end
  end
end

task "helm_chart_valid", ["helm_local_install"] do |_, args|
  task_runner(args) do |args|
    VERBOSE_LOGGING.info "helm_chart_valid" if check_verbose(args)
    VERBOSE_LOGGING.debug "helm_chart_valid args.raw: #{args.raw}" if check_verbose(args)
    VERBOSE_LOGGING.debug "helm_chart_valid args.named: #{args.named}" if check_verbose(args)

    response = String::Builder.new

    # config = cnf_conformance_yml
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    helm_directory = config.get("helm_directory").as_s
    # helm_chart_repo = config.get("helm_chart").as_s

    if args.named.keys.includes? "cnf_chart_path"
      helm_directory = args.named["cnf_chart_path"]
    end

    VERBOSE_LOGGING.debug "helm_directory: #{helm_directory}" if check_verbose(args)
    # VERBOSE_LOGGING.debug "helm_chart_repo: #{helm_chart_repo}" if check_verbose(args)

    current_dir = FileUtils.pwd 
    VERBOSE_LOGGING.debug current_dir if check_verbose(args)
    #helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    helm = CNFSingleton.helm

    # current_cnf_dir_short_name = CNFManager.ensure_cnf_conformance_dir
    # VERBOSE_LOGGING.debug current_cnf_dir_short_name if check_verbose(args)
    # destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    # VERBOSE_LOGGING.debug destination_cnf_dir if check_verbose(args)
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    ls_helm_directory = `ls -al #{destination_cnf_dir}/#{helm_directory}`
    VERBOSE_LOGGING.debug "ls -al of helm_directory: #{ls_helm_directory}" if check_verbose(args)

    helm_lint = `#{helm} lint #{destination_cnf_dir}/#{helm_directory}`
    VERBOSE_LOGGING.debug "helm_lint: #{helm_lint}" if check_verbose(args)

    if $?.success? 
      upsert_passed_task("helm_chart_valid", "✔️  PASSED: Helm Chart #{helm_directory} Lint Passed")
    else
      upsert_failed_task("helm_chart_valid", "✖️  FAILURE: Helm Chart #{helm_directory} Lint Failed")
    end
  end
end

task "validate_config" do |_, args|
  yml = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
  valid, warning_output = CNFManager.validate_cnf_conformance_yml(yml)
  emoji_config="📋"
  if valid
    stdout_success "✔️ PASSED: CNF configuration validated #{emoji_config}"
  else
    stdout_failure "❌ FAILURE: Critical Error with CNF Configuration. Please review USAGE.md for steps to set up a valid CNF configuration file #{emoji_config}"
  end
end
