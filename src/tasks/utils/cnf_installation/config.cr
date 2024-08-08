require "yaml"

module CNFInstall
  module Config
    @[YAML::Serializable::Options(emit_nulls: true)]

    class ConfigBase
      include YAML::Serializable
    end

    class Config < ConfigBase
      @config_version : String
      @common_parameters : CommonParameters | Nil
      @dynamic_parameters : DynamicParameters | Nil
      @deployments : DeploymentsConfig
      getter config_version, common_parameters, dynamic_parameters, deployments
    end

    class CommonParameters < ConfigBase
      @service_name : String | Nil
      @rolling_update_tag : String | Nil
      @container_names : Array(Hash(String, String)) | Nil
      @white_list_container_names : Array(String) | Nil
      @docker_insecure_registries : Array(String) | Nil
      @image_registry_fqdns : Hash(String, String) | Nil
      @five_g_parameters : FiveGParameters | Nil
      getter service_name, rolling_update_tag, container_names, white_list_container_names
      getter docker_insecure_registries, image_registry_fqdns, five_g_parameters
    end

    class DynamicParameters < ConfigBase
      @source_cnf_file : String | Nil
      @source_cnf_dir : String | Nil
      @yml_file_path : String | Nil
      property source_cnf_file, source_cnf_dir, yml_file_path
    end

    class DeploymentsConfig < ConfigBase
      @helm_charts : Array(HelmChartConfig) | Nil
      @helm_directories : Array(HelmDirectoryConfig) | Nil
      @manifests : Array(ManifestDirectoryConfig) | Nil
      getter helm_charts, helm_directories, manifests

      def after_initialize
        unless @helm_charts || @helm_directories || @manifests
          raise YAML::Error.new("At least one deployment should be configured")
        end
        
        deployment_names = Set(String).new
        {@helm_charts, @helm_directories, @manifests}.each do |deployment_array|
          if deployment_array
            deployment_array.each do |deployment|
              if deployment_names.includes?(deployment.name)
                raise YAML::Error.new("Deployment names should be unique: \"#{deployment.name}\"")
              else
                deployment_names.add(deployment.name)
              end
            end
          end
        end
      end
    end

    class DeploymentConfig < ConfigBase
      @name : String
      getter name
    end

    class HelmChartConfig < DeploymentConfig
      @helm_repo_name : String
      @helm_repo_url : String
      @helm_chart_name : String
      @helm_values : String | Nil
      @namespace : String | Nil
      getter helm_repo_name, helm_repo_url, helm_chart_name, helm_values, namespace
    end

    class HelmDirectoryConfig < DeploymentConfig
      @helm_directory : String
      @helm_chart_path : String | Nil
      @helm_values : String | Nil
      @namespace : String | Nil
      getter helm_directory, helm_chart_path, helm_values, namespace

      def after_initialize
        unless @helm_chart_path
          @helm_chart_path = "#{helm_directory}Chart.yaml"
        end
      end
    end

    class ManifestDirectoryConfig < DeploymentConfig
      @manifest_directory : String
      getter manifest_directory
    end

    class FiveGParameters < ConfigBase
      @amf_label : String | Nil
      @smf_label : String | Nil
      @upf_label : String | Nil
      @ric_label : String | Nil
      @amf_service_name : String | Nil
      @mmc : String | Nil
      @mnc : String | Nil
      @sst : String | Nil
      @sd : String | Nil
      @tac : String | Nil
      @protectionScheme : String | Nil
      @publicKey : String | Nil
      @publicKeyId : String | Nil
      @routingIndicator : String | Nil
      @enabled : String | Nil
      @count : String | Nil
      @initialMSISDN : String | Nil
      @key : String | Nil
      @op : String | Nil
      @opType : String | Nil
      @type : String | Nil
      @apn : String | Nil
      @emergency : String | Nil
      
    end

    class InvalidDeploymentConfigError < YAML::Error
      def initialize(deployment_type, mandatory_parameters)
        super("#{deployment_type} deployment config should contain all mandatory parameters: #{mandatory_parameters}")
      end
    end

    def self.parse_cnf_config(path_to_config)
      yaml_content = File.read(path_to_config)
      begin
        config = Config.from_yaml(yaml_content)
      rescue exception
        stdout_failure exception.message
        exit 1
      end
      puts config.inspect
    end
  end
end
