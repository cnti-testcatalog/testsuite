require "yaml"

module CNFInstall
  module Config
    # Base class for configuration
    # WILL BE REBASED ELSEWHERE
    class ConfigBase
      include YAML::Serializable
      include YAML::Serializable::Strict
    end

    # REQUIRES FUTURE EXTENSION in case of new config format.
    enum ConfigVersion
      V1
      V2
      Latest = V2
    end

    class ConfigTransformer
      @new_config : YAML::Any
      @old_config : ConfigBase
      @version : ConfigVersion

      # The initializer reads the config file twice to determine the config version 
      # of @old_config, this cannot be removed due to later parsing to appropriate class.
      def initialize(old_config_path : String)
        tmp_content = File.read(old_config_path)
        yaml_content = YAML.parse(tmp_content).as_h

        # Automatic version detection to streamline the transformation
        @version = detect_version(yaml_content)
        if @version == ConfigVersion::Latest
          stdout_warning "Your config is the latest version."
          exit(1)
        end

        @new_config = YAML::Any.new({} of YAML::Any => YAML::Any)
        @old_config = parse_old_config(tmp_content)
      end

      # Serialize the transformed config to a string.
      def serialize_to_string : String
        YAML.dump(@new_config)
      end

      # Serialize the transformed config to a file and return the file path.
      def serialize_to_file(file_path : String) : String
        File.write(file_path, serialize_to_string)
        file_path
      end

      # Detects the config version.
      # REQUIRES FUTURE EXTENSION in case of new config format.
      private def detect_version(yaml_content : Hash(YAML::Any, YAML::Any)) : ConfigVersion
        version_value = yaml_content["config_version"]?.try(&.to_s)

        if version_value
          begin
            ConfigVersion.parse(version_value.upcase)
          rescue ex : Exception
            raise UnsupportedConfigVersionError.new(version_value)
          end
        else
          ConfigVersion::V1
        end
      end

      # Parses the config to the correct class.
      # REQUIRES FUTURE EXTENSION in case of new config format.
      private def parse_old_config(tmp_content : String) : ConfigBase
        begin
          case @version
          when ConfigVersion::V1
            ConfigV1.from_yaml(tmp_content)
          else
            raise UnsupportedConfigVersionError.new(@version)
          end
        rescue ex : YAML::ParseException
          # This is usually raised in case of unexpected YAML keys.
          stdout_failure "Failed to parse config: #{ex.message}."
          stdout_failure "Please check your YAML fields for correctness."
          exit(1)
        end
      end

      # Performs the transformation from V1 to V2.
      # REQUIRES FUTURE EXTENSION in case of new config format.
      def transform
        case @version
        when ConfigVersion::V1
          @new_config = V1ToV2Transformation.new(@old_config.as(ConfigV1)).transform
        else
          raise UnsupportedConfigVersionError.new(@version)
        end
      end
    end

    class UnsupportedConfigVersionError < Exception
      def initialize(version : ConfigVersion | String)
        super "Unsupported configuration version: #{version.is_a?(ConfigVersion) ? version.to_s.downcase : version}"
      end
    end
  end
end    