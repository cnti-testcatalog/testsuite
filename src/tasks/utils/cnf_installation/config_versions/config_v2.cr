module CNFInstall
  module ConfigV2
    @[YAML::Serializable::Options(emit_nulls: true)]
    alias AnyDeploymentConfig = HelmChartConfig | HelmDirectoryConfig | ManifestDirectoryConfig

    class ConfigBase
      include YAML::Serializable
      include YAML::Serializable::Strict
    end

    class Config < ConfigBase
      getter config_version : String,
             common = CommonParameters.new(),
             dynamic = DynamicParameters.new(),
             deployments : DeploymentsConfig
    end

    class CommonParameters < ConfigBase
      getter container_names = [] of ContainerParameters,
             white_list_container_names = [] of String,
             docker_insecure_registries = [] of String,
             image_registry_fqdns = {} of String => String,
             five_g_parameters = FiveGParameters.new()
      def initialize()
      end
    end

    class DynamicParameters < ConfigBase
      property  source_cnf_dir = "",
                destination_cnf_dir = "",
                install_method : Tuple(CNFInstall::InstallMethod, String) = {CNFInstall::InstallMethod::Invalid, ""} 
      def initialize()
      end
    end

    class DeploymentsConfig < ConfigBase
      getter helm_charts = [] of HelmChartConfig,
             helm_dirs = [] of HelmDirectoryConfig,
             manifests = [] of ManifestDirectoryConfig
      # deployments.current and all related functionality should be removed with new installation process.
      @@current : AnyDeploymentConfig | Nil

      def after_initialize
        if @helm_charts.empty? && @helm_dirs.empty? && @manifests.empty?
          raise YAML::Error.new("At least one deployment should be configured")
        end
        
        # To be removed with new installation process.
        if @helm_charts.size + @helm_dirs.size + @manifests.size > 1 
          raise YAML::Error.new("Multiple deployments are not supported yet")
        end

        deployment_names = Set(String).new
        {@helm_charts, @helm_dirs, @manifests}.each do |deployment_array|
          if deployment_array && !deployment_array.empty?
            
            # To be removed with new installation process.
            @@current = deployment_array[0]

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

      # To be removed with new installation process.
      def get_deployment_param(param : Symbol) : String
        current = @@current.not_nil!
        allowed_params = [
                          :name, :helm_repo_name, :helm_repo_url, :helm_chart_name,
                          :helm_values, :namespace, :helm_directory, :manifest_directory
                          ]
        if !allowed_params.includes?(param)
          raise ArgumentError.new("Unknown symbol for deployment: #{param}")
        end
        result = case current
        when HelmChartConfig
          case param
          when :name            then current.name
          when :helm_repo_name  then current.helm_repo_name
          when :helm_repo_url   then current.helm_repo_url
          when :helm_chart_name then current.helm_chart_name
          when :helm_values     then current.helm_values
          when :namespace       then current.namespace
          else ""
          end
        when HelmDirectoryConfig
          case param
          when :name           then current.name
          when :helm_directory then current.helm_directory
          when :helm_values    then current.helm_values
          when :namespace      then current.namespace
          else ""
          end
        when ManifestDirectoryConfig
          case param
          when :name               then current.name
          when :manifest_directory then current.manifest_directory
          else ""
          end
        end
        result || ""
      end

      # To be removed with new installation process.
      def get_install_method
        case @@current
        when HelmChartConfig
          {CNFInstall::InstallMethod::HelmChart, get_deployment_param(:helm_chart_name)}
        when HelmDirectoryConfig
          full_helm_directory = Path[CNF_DIR + "/" + get_deployment_param(:name)  + "/" + CNFManager.sandbox_helm_directory(get_deployment_param(:helm_directory))].expand.to_s
          {CNFInstall::InstallMethod::HelmDirectory, full_helm_directory}
        when ManifestDirectoryConfig
          full_manifest_directory = Path[CNF_DIR + "/" + get_deployment_param(:name) + "/" + CNFManager.sandbox_helm_directory(get_deployment_param(:manifest_directory))].expand.to_s
          {CNFInstall::InstallMethod::ManifestDirectory, full_manifest_directory}
        else 
          raise YAML::Error.new("At least one deployment should be configured")
        end
      end
    end

    class DeploymentConfig < ConfigBase
      getter name : String
    end

    class HelmDeploymentConfig < DeploymentConfig
      getter helm_values = "",
             namespace = ""
      
    end

    class HelmChartConfig < HelmDeploymentConfig
      getter helm_repo_name : String,
             helm_repo_url : String,
             helm_chart_name : String
    end

    class HelmDirectoryConfig < HelmDeploymentConfig
      getter helm_directory : String
    end

    class ManifestDirectoryConfig < DeploymentConfig
      getter manifest_directory : String
    end

    class FiveGParameters < ConfigBase
      getter amf_label = "",
             smf_label = "",
             upf_label = "",
             ric_label = "",
             amf_service_name = "",
             mmc = "",
             mnc = "",
             sst = "",
             sd = "",
             tac = "",
             protectionScheme = "",
             publicKey = "",
             publicKeyId = "",
             routingIndicator = "",
             enabled = "",
             count = "",
             initialMSISDN = "",
             key = "",
             op = "",
             opType = "",
             type = "",
             apn = "",
             emergency = ""

      def initialize()
      end
    end
    
    class ContainerParameters < ConfigBase
      getter name = "",
             rolling_update_test_tag = "",
             rolling_downgrade_test_tag = "",
             rolling_version_change_test_tag = "",
             rollback_from_tag = ""
    end
  end
end