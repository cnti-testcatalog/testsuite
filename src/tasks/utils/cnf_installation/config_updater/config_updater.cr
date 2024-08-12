require "yaml"

module CNFInstall
  module Config
    class ConfigUpdater
      @output_config : YAML::Any
      @input_config : ConfigBase
      @version : ConfigVersion

      # This approach could be extended in future by making use of abstract classes,
      # which would remove the need for hashes. 
      # Define transformation rules at the top of the class
      # REQUIRES FUTURE EXTENSION in case of new config format.
      VERSION_TRANSFORMATIONS = {
        ConfigVersion::V1 => ->(input_config : ConfigBase) { V1ToV2Transformation.new(input_config.as(ConfigV1)).transform }
      }

      # Define parsing rules at the top of the class
      # REQUIRES FUTURE EXTENSION in case of new config format.
      VERSION_PARSERS = {
        ConfigVersion::V1 => ->(raw_input_config : String) { ConfigV1.from_yaml(raw_input_config) }
      }

      def initialize(raw_input_config : String)
        # Automatic version detection to streamline the transformation
        @version = CNFInstall::Config.detect_version(raw_input_config)
        @output_config = YAML::Any.new({} of YAML::Any => YAML::Any)
        @input_config = parse_input_config(raw_input_config)
      end

      # Serialize the updated config to a string.
      def serialize_to_string : String
        YAML.dump(@output_config)
      end

      # Serialize the updated config to a file and return the file path.
      def serialize_to_file(file_path : String) : String
        File.write(file_path, serialize_to_string)
        file_path
      end

      # Parses the config to the correct class.
      # Uses the VERSION_PARSERS hash.
      private def parse_input_config(raw_input_config : String) : ConfigBase
        parser = VERSION_PARSERS[@version]
        if parser
          begin
            parser.call(raw_input_config)
          rescue ex : YAML::ParseException
            stdout_failure "Failed to parse config: #{ex.message}."
            exit(1)
          end
        else
          raise UnsupportedConfigVersionError.new(@version)
        end
      end

      # Performs the transformation from Vx to Vy.
      # Uses the VERSION_TRANSFORMATIONS hash.
      def transform
        transformer = VERSION_TRANSFORMATIONS[@version]
        if transformer
          @output_config = transformer.call(@input_config)
        else
          raise UnsupportedConfigVersionError.new(@version)
        end
      end
    end

    class UnsupportedConfigVersionError < Exception
      def initialize(version : ConfigVersion | String)
        super "Unsupported configuration version detected: #{version.is_a?(ConfigVersion) ? version.to_s.downcase : version}"
      end
    end
  end
end    