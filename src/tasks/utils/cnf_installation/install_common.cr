require "../utils.cr"

module CNFInstall
  enum InstallMethod
    HelmChart
    HelmDirectory
    ManifestDirectory 
    Invalid
  end

  def self.install_method_by_config_src(config_src : String) : InstallMethod
    Log.info { "install_method_by_config_src" }
    Log.info { "config_src: #{config_src}" }
    helm_chart_file = "#{config_src}/#{Helm::CHART_YAML}"
    Log.info { "looking for potential helm_chart_file: #{helm_chart_file}: file exists?: #{File.exists?(helm_chart_file)}" }

    if !Dir.exists?(config_src) 
      Log.info { "install_method_by_config_src helm_chart selected" }
      InstallMethod::HelmChart
    elsif File.exists?(helm_chart_file)
      Log.info { "install_method_by_config_src helm_directory selected" }
      InstallMethod::HelmDirectory
    elsif Dir.exists?(config_src) 
      Log.info { "install_method_by_config_src manifest_directory selected" }
      InstallMethod::ManifestDirectory
    else
      puts "Error: #{config_src} is neither a helm_chart, helm_directory, or manifest_directory.".colorize(:red)
      exit 1
    end
  end

  #Determine, for cnf, whether a helm chart, helm directory, or manifest directory is being used for installation
  def self.cnf_installation_method(config : Totem::Config) : Tuple(CNFInstall::InstallMethod, String)
    Log.info { "cnf_installation_method" }
    Log.info { "cnf_installation_method config: #{config}" }
    Log.info { "cnf_installation_method config: #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}" }
    helm_chart = optional_key_as_string(config, "helm_chart")
    helm_directory = ensure_directory(optional_key_as_string(config, "helm_directory"))
    manifest_directory = optional_key_as_string(config, "manifest_directory")
    release_name = optional_key_as_string(config, "release_name")
    full_helm_directory = ""
    full_manifest_directory = ""
    Log.info { "release_name: #{release_name}" }
    Log.info { "helm_directory: #{helm_directory}" }
    Log.info { "manifest_directory: #{manifest_directory}" }
    #todo did this ever work? should be full path to destination.  This is not 
    # even the relative path
    if Dir.exists?(helm_directory) 
      Log.info { "Change helm_directory relative path into full path" }
      full_helm_directory = Path[CNFManager.sandbox_helm_directory(helm_directory)].expand.to_s
    elsif Dir.exists?(manifest_directory)
      Log.info { "Change manifest_directory relative path into full path" }
      full_manifest_directory = Path[manifest_directory].expand.to_s
    else
      Log.info { "Building helm_directory and manifest_directory full paths" }
      full_helm_directory = Path[CNF_DIR + "/" + release_name + "/" + CNFManager.sandbox_helm_directory(helm_directory)].expand.to_s
      full_manifest_directory = Path[CNF_DIR + "/" + release_name + "/" + CNFManager.sandbox_helm_directory(manifest_directory)].expand.to_s
    end

    Log.info { "full_helm_directory: #{full_helm_directory} exists? #{Dir.exists?(full_helm_directory)}" }
    Log.info { "full_manifest_directory: #{full_manifest_directory} exists? #{Dir.exists?(full_manifest_directory)}" }

    unless exclusive_install_method_tags?(config)
      puts "Error: Must populate at lease one installation type in #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}: choose either helm_chart, helm_directory, or manifest_directory in cnf-testsuite.yml!".colorize(:red)
      exit 1
    end

    if !helm_chart.empty?
      {CNFInstall::InstallMethod::HelmChart, helm_chart}
    elsif !helm_directory.empty?
      Log.info { "helm_directory not empty, using: #{full_helm_directory}" }
      {CNFInstall::InstallMethod::HelmDirectory, full_helm_directory}
    elsif !manifest_directory.empty?
      Log.info { "manifest_directory not empty, using: #{full_manifest_directory}" }
      {CNFInstall::InstallMethod::ManifestDirectory, full_manifest_directory}
    else
      puts "Error: Must populate at lease one installation type in #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}: choose either helm_chart, helm_directory, or manifest_directory.".colorize(:red)
      exit 1
    end
  end

  def self.exclusive_install_method_tags?(config)
    installation_type_count = ["helm_chart", "helm_directory", "manifest_directory"].reduce(0) do |acc, install_type|
      begin
        test_tag = config[install_type]
        Log.debug { "install type count install_type: #{install_type}" }
        if install_type.empty?
          acc
        else
          acc = acc + 1
        end
      rescue ex
        Log.debug { "install_type: #{install_type} not found in #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}" }
        acc
      end
    end
    Log.debug { "installation_type_count: #{installation_type_count}" }
    if installation_type_count > 1
      false
    else
      true
    end
  end

  def self.install_parameters(config)
    Log.info { "install_parameters" }
    install_method = config.cnf_config[:install_method]
    helm_chart = config.cnf_config[:helm_chart]
    helm_directory = config.cnf_config[:helm_directory]
    manifest_directory = config.cnf_config[:manifest_directory]
    case install_method[0]
    when CNFInstall::InstallMethod::ManifestDirectory
      directory_parameters = directory_parameter_split(manifest_directory)["parameters"]
    when CNFInstall::InstallMethod::HelmChart
      directory_parameters = directory_parameter_split(helm_chart)["parameters"]
    when CNFInstall::InstallMethod::HelmDirectory
      directory_parameters = directory_parameter_split(helm_directory)["parameters"]
    else
      directory_parameters = ""
    end
    Log.info { "directory_parameters :#{directory_parameters}" }
    directory_parameters
  end

  def self.directory_parameter_split(directory_with_parameters)
    Log.info { "directory_parameter_split : #{directory_with_parameters}" }
    directory = directory_with_parameters.split(" ")[0]
    parameters = directory_with_parameters.split(" ")[1..-1].join(" ") 
    Log.info { "directory : #{directory} parameters: #{parameters}"} 
    {"directory" => directory, "parameters" => parameters} 
  end

  def self.ensure_directory(directory_with_parameters)
    Log.info { "directory_parameter_split : #{directory_with_parameters}" }
    split = directory_parameter_split(directory_with_parameters)
    split["directory"]
  end

end