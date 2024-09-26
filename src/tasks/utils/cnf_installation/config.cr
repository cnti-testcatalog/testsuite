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
      
      config.dynamic.initialize_dynamic_properties(config, config_dir)

      config
    end

    # Detects the config version.
    def self.detect_version(tmp_content : String) : ConfigVersion
      yaml_content = YAML.parse(tmp_content).as_h
      version_value = yaml_content["config_version"]?.try(&.to_s)

      if version_value
        begin
          ConfigVersion.parse(version_value.upcase)
        rescue ex : ArgumentError
          raise UnsupportedConfigVersionError.new(version_value)
        end
      else
        # Default to V1 if no version is specified
        ConfigVersion::V1
      end
    end

    def self.config_version_is_latest?(tmp_content : String) : Bool
      detect_version(tmp_content) == ConfigVersion::Latest
    end
  end
end
