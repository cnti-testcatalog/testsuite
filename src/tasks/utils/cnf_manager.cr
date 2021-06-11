# coding: utf-8
require "totem"
require "colorize"
require "crinja"
require "./types/cnf_testsuite_yml_type.cr"
require "./helm.cr"
require "./git_client.cr"
require "uuid"
require "./points.cr"
require "./task.cr"
require "./config.cr"
require "./generate_config.cr"

module CNFManager


  # TODO: figure out recursively check for unmapped json and warn on that
  # https://github.com/Nicolab/crystal-validator#check
  def self.validate_cnf_testsuite_yml(config)
    ccyt_validator = nil
    valid = true

    begin
      ccyt_validator = CnfTestSuiteYmlType.from_json(config.settings.to_json)
    rescue ex
      valid = false
      LOGGING.error "✖ ERROR: cnf_testsuite.yml field validation error.".colorize(:red)
      LOGGING.error " please check info in the the field name near the text 'CnfTestSuiteYmlType#' in the error below".colorize(:red)
      LOGGING.error ex.message
      ex.backtrace.each do |x|
        LOGGING.error x
      end
    end

    unmapped_keys_warning_msg = "WARNING: Unmapped cnf_testsuite.yml keys. Please add them to the validator".colorize(:yellow)
    unmapped_subkeys_warning_msg = "WARNING: helm_repository is unset or has unmapped subkeys. Please update your cnf_testsuite.yml".colorize(:yellow)


    if ccyt_validator && !ccyt_validator.try &.json_unmapped.empty?
      warning_output = [unmapped_keys_warning_msg] of String | Colorize::Object(String)
      warning_output.push(ccyt_validator.try &.json_unmapped.to_s)
      if warning_output.size > 1
        LOGGING.warn warning_output.join("\n")
      end
    end

    #TODO Differentiate between unmapped subkeys or unset top level key.
    if ccyt_validator && !ccyt_validator.try &.helm_repository.try &.json_unmapped.empty?
      root = {} of String => (Hash(String, JSON::Any) | Nil)
      root["helm_repository"] = ccyt_validator.try &.helm_repository.try &.json_unmapped

      warning_output = [unmapped_subkeys_warning_msg] of String | Colorize::Object(String)
      warning_output.push(root.to_s)
      if warning_output.size > 1
        LOGGING.warn warning_output.join("\n")
      end
    end

    { valid, warning_output }
  end


  # Applies a block to each cnf resource
  #
  # `CNFManager.cnf_workload_resources(args, config) {|cnf_config, resource| #your code}
  def self.cnf_workload_resources(args, config, &block)
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    yml_file_path = config.cnf_config[:yml_file_path]
    helm_directory = config.cnf_config[:helm_directory]
    manifest_directory = config.cnf_config[:manifest_directory]
    release_name = config.cnf_config[:release_name]
    helm_chart_path = config.cnf_config[:helm_chart_path]
    manifest_file_path = config.cnf_config[:manifest_file_path]
    test_passed = true

    ##################
    # TODO extract exporting of manifest yml into separate function 
    if release_name.empty? # no helm chart
      template_ymls = Helm::Manifest.manifest_ymls_from_file_list(Helm::Manifest.manifest_file_list( destination_cnf_dir + "/" + manifest_directory))
    else
      Helm.generate_manifest_from_templates(release_name,
                                            helm_chart_path,
                                            manifest_file_path)
      template_ymls = Helm::Manifest.parse_manifest_as_ymls(manifest_file_path)
    end
    resource_ymls = Helm.all_workload_resources(template_ymls)
    # TODO call export manifest and get the resource ymls
		resource_resp = resource_ymls.map do | resource |
      resp = yield resource
      LOGGING.debug "cnf_workload_resource yield resp: #{resp}"
      resp
    end
    ###############




    resource_resp
  end

  #test_passes_completely = workload_resource_test do | cnf_config, resource, container, initialized |
  def self.workload_resource_test(args, config,
                                  check_containers = true,
                                  check_service = false,
                                  &block  : (NamedTuple(kind: YAML::Any, name: YAML::Any),
                                             JSON::Any, JSON::Any, Bool | Nil) -> Bool | Nil)
            # resp = yield resource, container, volumes, initialized
    test_passed = true
    resource_ymls = cnf_workload_resources(args, config) do |resource|
      resource
    end
    resource_names = Helm.workload_resource_kind_names(resource_ymls)
    LOGGING.info "resource names: #{resource_names}"
    if resource_names && resource_names.size > 0
      initialized = true
    else
      LOGGING.error "no resource names found"
      initialized = false
    end
		resource_names.each do | resource |
			VERBOSE_LOGGING.debug resource.inspect if check_verbose(args)
			volumes = KubectlClient::Get.resource_volumes(resource[:kind].as_s, resource[:name].as_s)
      VERBOSE_LOGGING.debug "check_service: #{check_service}" if check_verbose(args)
      VERBOSE_LOGGING.debug "check_containers: #{check_containers}" if check_verbose(args)
      case resource[:kind].as_s.downcase
      when "service"
        if check_service
          LOGGING.info "checking service: #{resource}"
          resp = yield resource, JSON.parse(%([{}])), volumes, initialized
          LOGGING.debug "yield resp: #{resp}"
          # if any response is false, the test fails
          test_passed = false if resp == false
        end
      else
				containers = KubectlClient::Get.resource_containers(resource[:kind].as_s, resource[:name].as_s)
				if check_containers
					containers.as_a.each do |container|
						resp = yield resource, container, volumes, initialized
						LOGGING.debug "yield resp: #{resp}"
						# if any response is false, the test fails
						test_passed = false if resp == false
					end
				else
					resp = yield resource, containers, volumes, initialized
					LOGGING.debug "yield resp: #{resp}"
					# if any response is false, the test fails
					test_passed = false if resp == false
				end
      end
		end
    LOGGING.debug "workload resource test intialized: #{initialized} test_passed: #{test_passed}"
    initialized && test_passed
  end

  def self.cnf_installed?
    LOGGING.info("cnf_config_list")
    LOGGING.info("find: find #{CNF_DIR}/* -name #{CONFIG_FILE}")
    cnf_testsuite = `find #{CNF_DIR}/* -name "#{CONFIG_FILE}"`.split("\n").select{|x| x.empty? == false}
    LOGGING.info("find response: #{cnf_testsuite}")
    if cnf_testsuite.size == 0 
      false
    else 
      true
    end
  end

  def self.cnf_config_list(silent=false)
    LOGGING.info("cnf_config_list")
    LOGGING.info("find: find #{CNF_DIR}/* -name #{CONFIG_FILE}")
    cnf_testsuite = `find #{CNF_DIR}/* -name "#{CONFIG_FILE}"`.split("\n").select{|x| x.empty? == false}
    LOGGING.info("find response: #{cnf_testsuite}")
    if cnf_testsuite.size == 0 && !silent
      raise "No cnf_testsuite.yml found! Did you run the setup task?"
    end
    cnf_testsuite
  end

  def self.destination_cnfs_exist?
    cnf_config_list(silent=true).size > 0
  end

  def self.parsed_config_file(path)
    if path && path.empty?
      raise "No cnf_testsuite.yml found in #{path}!"
    end
    Totem.from_file "#{path}"
  end

  def self.sample_testsuite_yml(sample_dir)
    LOGGING.info "sample_testsuite_yml sample_dir: #{sample_dir}"
    cnf_testsuite = `find #{sample_dir}/* -name "cnf-testsuite.yml"`.split("\n")[0]
    if cnf_testsuite.empty?
      raise "No cnf_testsuite.yml found in #{sample_dir}!"
    end
    Totem.from_file "./#{cnf_testsuite}"
  end

  def self.path_has_yml?(config_path)
    if config_path =~ /\.yml/
      true
    else
      false
    end
  end

  def self.config_from_path_or_dir(cnf_path_or_dir)
    if path_has_yml?(cnf_path_or_dir)
      config_file = File.dirname(cnf_path_or_dir)
      config = sample_testsuite_yml(config_file)
    else
      config_file = cnf_path_or_dir
      config = sample_testsuite_yml(config_file)
    end
    return config
  end

  # if passed a directory, adds cnf-testsuite.yml to the string
  def self.ensure_cnf_testsuite_yml_path(path : String)
    LOGGING.info("ensure_cnf_testsuite_yml_path")
    if path_has_yml?(path)
      yml = path
    else
      yml = path + "/cnf-testsuite.yml"
    end
  end

  def self.ensure_cnf_testsuite_dir(path)
    LOGGING.info("ensure_cnf_testsuite_yml_dir")
    if path_has_yml?(path)
      dir = File.dirname(path)
    else
      dir = path
    end
    dir + "/"
  end

  def self.release_name?(config)
    release_name = optional_key_as_string(config, "release_name").split(" ")[0]
    if release_name.empty?
      false
    else
      true
    end
  end

  def self.exclusive_install_method_tags?(config)
    installation_type_count = ["helm_chart", "helm_directory", "manifest_directory"].reduce(0) do |acc, install_type|
      begin
        test_tag = config[install_type]
        LOGGING.debug "install type count install_type: #{install_type}"
        if install_type.empty?
          acc
        else
          acc = acc + 1
        end
      rescue ex
        LOGGING.debug "install_type: #{install_type} not found in #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}"
        # LOGGING.debug ex.message
        # ex.backtrace.each do |x|
        #   LOGGING.debug x
        # end
        acc
      end
    end
    LOGGING.debug "installation_type_count: #{installation_type_count}"
    if installation_type_count > 1
      false
    else
      true
    end
  end

  def self.install_method_by_config_src(config_src : String)
    helm_chart_file = "#{config_src}/#{CHART_YAML}"
    LOGGING.debug "potential helm_chart_file: #{helm_chart_file}"

    if !Dir.exists?(config_src) 
      :helm_chart
    elsif File.exists?(helm_chart_file)
      :helm_directory
    elsif KubectlClient::Apply.validate(config_src)
      :manifest_directory
    else
      puts "Error: #{config_src} is neither a helm_chart, helm_directory, or manifest_directory.".colorize(:red)
      exit 1
    end
  end

  #Determine, for cnf, whether a helm chart, helm directory, or manifest directory is being used for installation
  def self.cnf_installation_method(config)
    LOGGING.info "cnf_installation_method"
    LOGGING.info "cnf_installation_method config: #{config}"
    LOGGING.info "cnf_installation_method config: #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}"
    helm_chart = optional_key_as_string(config, "helm_chart")
    helm_directory = optional_key_as_string(config, "helm_directory")
    manifest_directory = optional_key_as_string(config, "manifest_directory")

    unless CNFManager.exclusive_install_method_tags?(config)
      puts "Error: Must populate at lease one installation type in #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}: choose either helm_chart, helm_directory, or manifest_directory in cnf-testsuite.yml!".colorize(:red)
      exit 1
    end

    if !helm_chart.empty?
      {:helm_chart, helm_chart}
    elsif !helm_directory.empty?
      {:helm_directory, helm_directory}
    elsif !manifest_directory.empty?
      {:manifest_directory, manifest_directory}
    else
      puts "Error: Must populate at lease one installation type in #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}: choose either helm_chart, helm_directory, or manifest_directory.".colorize(:red)
      exit 1
    end
  end

  #TODO move to helm module
  def self.helm_template_header(helm_chart_or_directory, template_file="/tmp/temp_template.yml", airgapped=false)
    LOGGING.info "helm_template_header"
    helm = CNFSingleton.helm
    # generate helm chart release name
    # use --dry-run to generate yml file
    LOGGING.info  "airgapped mode: #{airgapped}"
    if airgapped
      # todo make tar info work with a directory
      info = TarClient.tar_info_by_config_src(helm_chart_or_directory)
      LOGGING.info  "airgapped mode info: #{info}"
      helm_chart_or_directory = info[:tar_name]
    end
    LOGGING.info("#{helm} install --dry-run --generate-name #{helm_chart_or_directory} > #{template_file}")
    helm_install = `#{helm} install --dry-run --generate-name #{helm_chart_or_directory} > #{template_file}`
    raw_template = File.read(template_file)
    split_template = raw_template.split("---")
    template_header = split_template[0]
    parsed_template_header = YAML.parse(template_header)
  end

  #TODO move to helm module
  def self.helm_chart_template_release_name(helm_chart_or_directory, template_file="/tmp/temp_template.yml", airgapped=false)
    LOGGING.info "helm_chart_template_release_name"
    hth = helm_template_header(helm_chart_or_directory, template_file, airgapped)
    LOGGING.debug "helm template: #{hth}"
    hth["NAME"]
  end


  def self.generate_and_set_release_name(config_yml_path, airgapped=false)
    LOGGING.info "generate_and_set_release_name"

    yml_file = CNFManager.ensure_cnf_testsuite_yml_path(config_yml_path)
    yml_path = CNFManager.ensure_cnf_testsuite_dir(config_yml_path)

    config = CNFManager.parsed_config_file(yml_file)

    predefined_release_name = optional_key_as_string(config, "release_name")
    LOGGING.debug "predefined_release_name: #{predefined_release_name}"
    if predefined_release_name.empty?
      install_method = self.cnf_installation_method(config)
      LOGGING.debug "install_method: #{install_method}"
      case install_method[0]
      when :helm_chart
        LOGGING.debug "helm_chart install method: #{install_method[1]}"
        release_name = helm_chart_template_release_name(install_method[1], airgapped: airgapped)
      when :helm_directory
        LOGGING.debug "helm_directory install method: #{yml_path}/#{install_method[1]}"
        release_name = helm_chart_template_release_name("#{yml_path}/#{install_method[1]}", airgapped: airgapped)
      when :manifest_directory
        LOGGING.debug "manifest_directory install method"
        release_name = UUID.random.to_s
      else
        raise "Install method should be either helm_chart, helm_directory, or manifest_directory"
      end
      #set generated helm chart release name in yml file
      LOGGING.debug "generate_and_set_release_name: #{release_name}"
      update_yml(yml_file, "release_name", release_name)
    end
  end


  # TODO move to sandbox module
  def self.cnf_destination_dir(config_file)
    LOGGING.info("cnf_destination_dir config_file: #{config_file}")
    if path_has_yml?(config_file)
      yml = config_file
    else
      yml = config_file + "/cnf-testsuite.yml"
    end
    config = parsed_config_file(yml)
    LOGGING.debug "cnf_destination_dir parsed_config_file config: #{config}"
    current_dir = FileUtils.pwd
    release_name = optional_key_as_string(config, "release_name").split(" ")[0]
    LOGGING.info "release_name: #{release_name}"
    LOGGING.info "cnf destination dir: #{current_dir}/#{CNF_DIR}/#{release_name}"
    "#{current_dir}/#{CNF_DIR}/#{release_name}"
  end

  def self.config_source_dir(config_file)
    if File.directory?(config_file)
      config_file
    else
      File.dirname(config_file)
    end
  end

  def self.helm_repo_add(helm_repo_name=nil, helm_repo_url=nil, args : Sam::Args=Sam::Args.new)
    LOGGING.info "helm_repo_add repo_name: #{helm_repo_name} repo_url: #{helm_repo_url} args: #{args.inspect}"
    ret = false
    if helm_repo_name == nil || helm_repo_url == nil
      # config = get_parsed_cnf_testsuite_yml(args)
      # config = parsed_config_file(ensure_cnf_testsuite_yml_path(args.named["cnf-config"].as(String)))
      config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(args.named["cnf-config"].as(String)))
      LOGGING.info "helm path: #{CNFSingleton.helm}"
      helm = CNFSingleton.helm
      # helm_repo_name = config.get("helm_repository.name").as_s?
      helm_repository = config.cnf_config[:helm_repository]
      helm_repo_name = "#{helm_repository && helm_repository["name"]}"
      helm_repo_url = "#{helm_repository && helm_repository["repo_url"]}"
      LOGGING.info "helm_repo_name: #{helm_repo_name}"
      # helm_repo_url = config.get("helm_repository.repo_url").as_s?
      LOGGING.info "helm_repo_url: #{helm_repo_url}"
    end
    if helm_repo_name && helm_repo_url
      ret = Helm.helm_repo_add(helm_repo_name, helm_repo_url)
    else
      ret = false
    end
    ret
  end

  def self.sample_setup_cli_args(args, noisy=true)
    VERBOSE_LOGGING.info "sample_setup_cli_args" if check_verbose(args)
    VERBOSE_LOGGING.debug "args = #{args.inspect}" if check_verbose(args)
    if args.named.keys.includes? "cnf-config"
      yml_file = args.named["cnf-config"].as(String)
      cnf_path = File.dirname(yml_file)
    elsif args.named.keys.includes? "cnf-path"
      cnf_path = args.named["cnf-path"].as(String)
    elsif noisy
      stdout_failure "Error: You must supply either cnf-config or cnf-path"
      exit 1
    else
      cnf_path = ""
    end
    if args.named.keys.includes? "wait_count"
      wait_count = args.named["wait_count"].to_i
    elsif args.named.keys.includes? "wait-count"
      wait_count = args.named["wait-count"].to_i
    else
      wait_count = 180
    end
    output_file = args.named["airgapped"].as(String) if args.named["airgapped"]?
    output_file = args.named["output-file"].as(String) if args.named["output-file"]?
    output_file = args.named["of"].as(String) if args.named["if"]?
    input_file = args.named["offline"].as(String) if args.named["offline"]?
    input_file = args.named["input-file"].as(String) if args.named["input-file"]?
    input_file = args.named["if"].as(String) if args.named["if"]?
    airgapped=false
    airgapped=true if args.raw.includes?("airgapped")

    cli_args = {config_file: cnf_path, extended_config_file: yml_file, wait_count: wait_count, verbose: check_verbose(args), output_file: output_file, input_file: input_file}
    LOGGING.debug "cli_args: #{cli_args}"
    cli_args
  end

  # Create a unique directory for the cnf that is to be installed under ./cnfs
  # Only copy the cnf's cnf-testsuite.yml and it's helm_directory or manifest directory (if it exists)
  # Use manifest directory if helm directory empty
  def self.sandbox_setup(config, cli_args)
    LOGGING.info "sandbox_setup"
    LOGGING.info "sandbox_setup config: #{config.cnf_config}"
    verbose = cli_args[:verbose]
    config_file = config.cnf_config[:source_cnf_dir]
    release_name = config.cnf_config[:release_name]
    install_method = config.cnf_config[:install_method]
    helm_directory = config.cnf_config[:helm_directory]
    manifest_directory = config.cnf_config[:manifest_directory]
    helm_chart_path = config.cnf_config[:helm_chart_path]
    destination_cnf_dir = CNFManager.cnf_destination_dir(config_file)

    if install_method[0] == :manifest_directory
      manifest_or_helm_directory = config_source_dir(config_file) + "/" + manifest_directory
    elsif !helm_directory.empty?
      manifest_or_helm_directory = config_source_dir(config_file) + "/" + helm_directory
    else
      # this is not going to exist
      manifest_or_helm_directory = helm_chart_path #./cnfs/<cnf-release-name>/exported_chart
    end

    LOGGING.info("File.directory?(#{manifest_or_helm_directory}) #{File.directory?(manifest_or_helm_directory)}")
    # if the helm directory already exists, copy helm_directory contents into cnfs/<cnf-name>/<helm-directory-of-the-same-name>

    destination_chart_directory = {creation_type: :created, chart_directory: ""}
    if !manifest_or_helm_directory.empty? && manifest_or_helm_directory =~ /exported_chart/
      LOGGING.info "Ensuring exported helm directory is created"
      LOGGING.debug "mkdir_p destination_cnf_dir/exported_chart: #{manifest_or_helm_directory}"
      destination_chart_directory = {creation_type: :created,
                                     chart_directory: "#{manifest_or_helm_directory}"}
      FileUtils.mkdir_p(destination_chart_directory[:chart_directory])
    elsif !manifest_or_helm_directory.empty? && File.directory?(manifest_or_helm_directory)
      # if !manifest_or_helm_directory.empty? && File.directory?(manifest_or_helm_directory)
      LOGGING.info "Ensuring helm directory is copied"
      LOGGING.info("cp -a #{manifest_or_helm_directory} #{destination_cnf_dir}")
      destination_chart_directory = {creation_type: :copied,
                                     chart_directory: "#{manifest_or_helm_directory}"}
      yml_cp = `cp -a #{destination_chart_directory[:chart_directory]} #{destination_cnf_dir}`
      VERBOSE_LOGGING.info yml_cp if verbose
      raise "Copy of #{destination_chart_directory[:chart_directory]} to #{destination_cnf_dir} failed!" unless $?.success?
    end
    LOGGING.info "copy cnf-testsuite.yml file"
    LOGGING.info("cp -a #{ensure_cnf_testsuite_yml_path(config_file)} #{destination_cnf_dir}")
    yml_cp = `cp -a #{ensure_cnf_testsuite_yml_path(config_file)} #{destination_cnf_dir}`
    destination_chart_directory
  end

  # Retrieve the helm chart source
  def self.export_published_chart(config, cli_args)
    verbose = cli_args[:verbose]
    config_file = config.cnf_config[:source_cnf_dir]
    helm_directory = config.cnf_config[:helm_directory]
    helm_chart = config.cnf_config[:helm_chart]
    destination_cnf_dir = CNFManager.cnf_destination_dir(config_file)

    current_dir = FileUtils.pwd
    VERBOSE_LOGGING.info current_dir if verbose

    helm = CNFSingleton.helm
    LOGGING.info "helm path: #{CNFSingleton.helm}"

    LOGGING.debug "mkdir_p destination_cnf_dir/helm_directory: #{destination_cnf_dir}/#{helm_directory}"
    #TODO don't think we need to make this here
    FileUtils.mkdir_p("#{destination_cnf_dir}/#{helm_directory}")
    LOGGING.debug "helm command pull: #{helm} pull #{helm_chart}"
    #TODO move to helm module
    helm_pull = `#{helm} pull #{helm_chart}`
    VERBOSE_LOGGING.info helm_pull if verbose
    # TODO helm_chart should be helm_chart_repo
    # TODO make this into a tar chart function
    VERBOSE_LOGGING.info "mv #{Helm.chart_name(helm_chart)}-*.tgz #{destination_cnf_dir}/exported_chart" if verbose
    core_mv = `mv #{Helm.chart_name(helm_chart)}-*.tgz #{destination_cnf_dir}/exported_chart`
    VERBOSE_LOGGING.info core_mv if verbose

    VERBOSE_LOGGING.info "cd #{destination_cnf_dir}/exported_chart; tar -xvf #{destination_cnf_dir}/exported_chart/#{Helm.chart_name(helm_chart)}-*.tgz" if verbose
    tar = `cd #{destination_cnf_dir}/exported_chart; tar -xvf #{destination_cnf_dir}/exported_chart/#{Helm.chart_name(helm_chart)}-*.tgz`
    VERBOSE_LOGGING.info tar if verbose

    VERBOSE_LOGGING.info "mv #{destination_cnf_dir}/exported_chart/#{Helm.chart_name(helm_chart)}/* #{destination_cnf_dir}/exported_chart" if verbose
    move_chart = `mv #{destination_cnf_dir}/exported_chart/#{Helm.chart_name(helm_chart)}/* #{destination_cnf_dir}/exported_chart`
    VERBOSE_LOGGING.info move_chart if verbose
  ensure
    cd = `cd #{current_dir}`
    VERBOSE_LOGGING.info cd if verbose
  end

  #sample_setup({config_file: cnf_path, wait_count: wait_count})
  def self.sample_setup(cli_args)
    #TODO accept offline mode
    LOGGING.info "sample_setup cli_args: #{cli_args}"
    config_file = cli_args[:config_file]
    wait_count = cli_args[:wait_count]
    verbose = cli_args[:verbose]
    input_file = cli_args[:input_file]
    if input_file && !input_file.empty?
      config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file),true) 
    else
      config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file))
    end
    LOGGING.debug "config in sample_setup: #{config.cnf_config}"
    release_name = config.cnf_config[:release_name]
    install_method = config.cnf_config[:install_method]

    VERBOSE_LOGGING.info "sample_setup" if verbose
    LOGGING.info("config_file #{config_file}")
    # config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file))

    release_name = config.cnf_config[:release_name]
    install_method = config.cnf_config[:install_method]
    helm_directory = config.cnf_config[:helm_directory]
    manifest_directory = config.cnf_config[:manifest_directory]
    git_clone_url = config.cnf_config[:git_clone_url]
    helm_repository = config.cnf_config[:helm_repository]
    helm_repo_name = "#{helm_repository && helm_repository["name"]}"
    helm_repo_url = "#{helm_repository && helm_repository["repo_url"]}"
    LOGGING.info "helm_repo_name: #{helm_repo_name}"
    LOGGING.info "helm_repo_url: #{helm_repo_url}"

    #todo if in airgapped mode, set helm_chart in config to be the tarball path
    if input_file && !input_file.empty?
      tar_info = TarClient.tar_info_by_config_src(config.cnf_config[:helm_chart])
      helm_chart = tar_info[:tar_name]
    else
      helm_chart = config.cnf_config[:helm_chart]
    end
    helm_chart_path = config.cnf_config[:helm_chart_path]
    LOGGING.debug "helm_directory: #{helm_directory}"

    destination_cnf_dir = CNFManager.cnf_destination_dir(config_file)

    VERBOSE_LOGGING.info "destination_cnf_dir: #{destination_cnf_dir}" if verbose
    LOGGING.debug "mkdir_p destination_cnf_dir: #{destination_cnf_dir}"
    FileUtils.mkdir_p(destination_cnf_dir)

    GitClient.clone("#{git_clone_url} #{destination_cnf_dir}/#{release_name}")  if git_clone_url.empty? == false

    sandbox_setup(config, cli_args)

    helm = CNFSingleton.helm
    LOGGING.info "helm path: #{CNFSingleton.helm}"

    helm_install = {status: "", output: IO::Memory.new, error: IO::Memory.new}
    elapsed_time = Time.measure do
      #TODO offline mode for helm charts
      #TODO offline mode for helm directory
      #TODO offline mode for manifests
      #Get image from somewhere (cnf_yml)
      case install_method[0]
      when :manifest_directory
        VERBOSE_LOGGING.info "deploying by manifest file" if verbose
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{manifest_directory}")
      when :helm_chart
        if !helm_repo_name.empty? || !helm_repo_url.empty?
          Helm.helm_repo_add(helm_repo_name, helm_repo_url)
        end
        VERBOSE_LOGGING.info "deploying with chart repository" if verbose
        helm_intall = Helm.install("#{release_name} #{helm_chart}")
        export_published_chart(config, cli_args)
      when :helm_directory
        VERBOSE_LOGGING.info "deploying with helm directory" if verbose
        #TODO Add helm options into cnf-testsuite yml
        #e.g. helm install nsm --set insecure=true ./nsm/helm_chart
        helm_install = Helm.install("#{release_name} #{destination_cnf_dir}/#{helm_directory}")
      else
        raise "Deployment method not found"
      end

      resource_ymls = cnf_workload_resources(nil, config) do |resource|
        resource
      end
      resource_names = Helm.workload_resource_kind_names(resource_ymls)
      #TODO move to kubectlclient and make resource_install_and_wait_for_all function
      resource_names.each do | resource |
        case resource[:kind].as_s.downcase
        when "replicaset", "deployment", "statefulset", "pod", "daemonset"
          KubectlClient::Get.resource_wait_for_install(resource[:kind].as_s, resource[:name].as_s, wait_count)
        end
      end
    end

    LOGGING.info "elapsed_time.seconds: #{elapsed_time.seconds}"

    LOGGING.info "helm_install: #{helm_install}"
    LOGGING.info "helm_install[:output].to_s: #{helm_install[:output].to_s}"
    helm_used = false
    if helm_install && helm_install[:error].to_s.size == 0 # && helm_pull.to_s.size > 0
      helm_used = true
      stdout_success "Successfully setup #{release_name}"
    end


    if version_less_than(KubectlClient.server_version, "1.19.0")
      k8s_ver = false
    else
      k8s_ver = true 
    end

    # TODO save to an [preferrably immutable] config map 
    #TODO if helm_install then set helm_deploy = true in template
    LOGGING.info "save config"
    elapsed_time_template = Crinja.render(configmap_temp, { "helm_install" => helm_used, "release_name" => "cnf-testsuite-#{release_name}-startup-information", "elapsed_time" => "#{elapsed_time.seconds}", "k8s_ver" => "#{k8s_ver}"})
    #TODO find a way to kubectlapply directly without a map
    LOGGING.debug "elapsed_time_template : #{elapsed_time_template}"
    write_template= `echo "#{elapsed_time_template}" > "#{destination_cnf_dir}/configmap_test.yml"`
    # TODO if the config map exists on install, complain, delete then overwrite?
    KubectlClient::Delete.file("#{destination_cnf_dir}/configmap_test.yml")
    #TODO call kubectl apply on file
    KubectlClient::Apply.file("#{destination_cnf_dir}/configmap_test.yml")
    # TODO when uninstalling, remove config map
  end

def self.configmap_temp
  <<-TEMPLATE
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: '{{ release_name }}'
  {% if k8s_ver %}
  immutable: true
  {% endif %}
  data:
    startup_time: '{{ elapsed_time }}'
    helm_used: '{{ helm_used }}'
  TEMPLATE
end


  def self.sample_cleanup(config_file, force=false, installed_from_manifest=false, verbose=true)
    LOGGING.info "sample_cleanup"
    destination_cnf_dir = CNFManager.cnf_destination_dir(config_file)
    config = parsed_config_file(ensure_cnf_testsuite_yml_path(config_file))

    VERBOSE_LOGGING.info "cleanup config: #{config.inspect}" if verbose
    KubectlClient::Delete.file("#{destination_cnf_dir}/configmap_test.yml")
    release_name = "#{config.get("release_name").as_s?}"
    manifest_directory = destination_cnf_dir + "/" + "#{config["manifest_directory"]? && config["manifest_directory"].as_s?}"

    LOGGING.info "helm path: #{CNFSingleton.helm}"
    helm = CNFSingleton.helm
    dir_exists = File.directory?(destination_cnf_dir)
    ret = true
    LOGGING.info("destination_cnf_dir: #{destination_cnf_dir}")
    if dir_exists || force == true
      if installed_from_manifest
        # LOGGING.info "kubectl delete command: kubectl delete -f #{manifest_directory}"
        # kubectl_delete = `kubectl delete -f #{manifest_directory}`
        # ret = $?.success?
        ret = KubectlClient::Delete.file("#{manifest_directory}")
        # VERBOSE_LOGGING.info kubectl_delete if verbose
        # TODO put more safety around this
        rm = `rm -rf #{destination_cnf_dir}`
        VERBOSE_LOGGING.info rm if verbose
        if ret
          stdout_success "Successfully cleaned up #{manifest_directory} directory"
        end
      else
        LOGGING.info "helm uninstall command: #{helm} uninstall #{release_name.split(" ")[0]}"
        #TODO add capability to add helm options for uninstall
        helm_uninstall = `#{helm} uninstall #{release_name.split(" ")[0]}`
        ret = $?.success?
        VERBOSE_LOGGING.info helm_uninstall if verbose
        rm = `rm -rf #{destination_cnf_dir}`
        VERBOSE_LOGGING.info rm if verbose
        if ret
          stdout_success "Successfully cleaned up #{release_name.split(" ")[0]}"
        end
      end
    end
    ret
  end

  # TODO: figure out how to check this recursively
  #
  # def self.recursive_json_unmapped(hashy_thing): JSON::Any
  #   unmapped_stuff = hashy_thing.json_unmapped

  #   Hash(String, String).from_json(hashy_thing.to_json).each_key do |key|
  #     if hashy_thing.call(key).responds_to?(:json_unmapped)
  #       return unmapped_stuff[key] = recursive_json_unmapped(hashy_thing[key])
  #     end
  #   end

  #   unmapped_stuff
  # end


end
