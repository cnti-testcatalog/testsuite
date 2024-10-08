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
end