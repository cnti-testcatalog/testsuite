require "yaml"
require "../utils.cr"
require "./config_versions/config_v2.cr"

module CNFInstall
  module Config

    class Config < ConfigV2::Config
    end

    def self.parse_cnf_config_from_file(path_to_config)
      yaml_content = File.read(path_to_config)
      config_dir = CNFManager.ensure_cnf_testsuite_dir(path_to_config)
      begin
        parse_cnf_config_from_yaml(yaml_content, config_dir)
      rescue exception
        stdout_failure "Error during parsing CNF config on #{path_to_config}"
        stdout_failure exception.message
        stdout_failure "Please check your config according to the config template."
        exit 1
      end
    end

    def self.parse_cnf_config_from_yaml(yaml_content, config_dir)
      config = Config.from_yaml(yaml_content)
      
      if config.dynamic.source_cnf_dir.empty?
        config.dynamic.source_cnf_dir = config_dir
      end

      if config.dynamic.install_method[0].is_a?(CNFInstall::InstallMethod::Invalid)
        config.dynamic.install_method = config.deployments.get_install_method
      end

      if config.dynamic.destination_cnf_dir.empty?
        deployment_name = config.deployments.get_deployment_param(:name)
        current_dir = FileUtils.pwd
        config.dynamic.destination_cnf_dir = "#{current_dir}/#{CNF_DIR}/#{deployment_name}"
      end

      config
    end
  end
end
