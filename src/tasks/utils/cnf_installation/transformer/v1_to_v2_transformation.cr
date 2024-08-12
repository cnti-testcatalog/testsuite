module CNFInstall
  module Config
    # Rules for configV1 to configV2 transformation
    class V1ToV2Transformation < TransformationBase
      def transform : YAML::Any
        new_config_hash = {
          "config_version" => "v2",
          "common_parameters" => transform_common_parameters,
          "dynamic_parameters" => transform_dynamic_parameters,
          "deployments" => transform_deployments,
        }
      
        # Convert the entire native hash to stripped YAML::Any at the end.
        @new_config = process_data(new_config_hash).not_nil!
      end
      
      private def transform_common_parameters : Hash(String, Array(Hash(String, String | Nil)) | Array(String) | Hash(String, String | Nil))
        common_params = {} of String => Array(Hash(String, String | Nil)) | Array(String) | Hash(String, String | Nil)
      
        common_params = {
          "white_list_container_names" => @old_config.white_list_container_names,
          "docker_insecure_registries" => @old_config.docker_insecure_registries,
          "image_registry_fqdns" => @old_config.image_registry_fqdns,
          "container_names" => transform_container_names,
          "five_g_parameters" => transform_five_g_parameters
        }.compact
      
        common_params
      end
      
      private def transform_container_names : Array(Hash(String, String | Nil))
        if @old_config.container_names
          containers = @old_config.container_names.not_nil!.map do |container|
            {
              "name" => container.name,
              "rollback_from_tag" => container.rollback_from_tag,
              "rolling_update_test_tag" => container.rolling_update_test_tag,
              "rolling_downgrade_test_tag" => container.rolling_downgrade_test_tag,
              "rolling_version_change_test_tag" => container.rolling_version_change_test_tag
            }
          end
  
          return containers
        end
  
        [] of Hash(String, String | Nil)
      end
  
      private def transform_dynamic_parameters : Hash(String, String | Nil)
        {
          "source_cnf_dir" => @old_config.source_cnf_dir,
          "destination_cnf_dir" => @old_config.destination_cnf_dir
        }
      end
      
      private def transform_deployments : Hash(String, Array(Hash(String, String | Nil)))
        deployments = {} of String => Array(Hash(String, String | Nil))
  
        if @old_config.manifest_directory
          deployments["manifests"] = [{
            "name" => @old_config.release_name,
            "manifest_directory" => @old_config.manifest_directory
          }]
        elsif @old_config.helm_directory
          deployments["helm_directories"] = [{
            "name" => @old_config.release_name,
            "helm_directory" => @old_config.helm_directory,
            "helm_values" => @old_config.helm_values,
            "namespace" => @old_config.helm_install_namespace
          }]
        elsif @old_config.helm_chart
          helm_chart_data = {
            "name" => @old_config.release_name,
            "helm_chart_name" => @old_config.helm_chart,
            "helm_values" => @old_config.helm_values,
            "namespace" => @old_config.helm_install_namespace
          }
        
          if @old_config.helm_repository
            helm_chart_data["helm_repo_name"] = @old_config.helm_repository.not_nil!.name
            helm_chart_data["helm_repo_url"] = @old_config.helm_repository.not_nil!.repo_url
          end
        
          deployments["helm_charts"] = [helm_chart_data]
        end
      
        deployments
      end
      
      private def transform_five_g_parameters : Hash(String, String | Nil)
        {
          "core" => @old_config.core,
          "amf_label" => @old_config.amf_label,
          "smf_label" => @old_config.smf_label,
          "upf_label" => @old_config.upf_label,
          "ric_label" => @old_config.ric_label,
          "amf_service_name" => @old_config.amf_service_name,
          "mmc" => @old_config.mmc,
          "mnc" => @old_config.mnc,
          "sst" => @old_config.sst,
          "sd" => @old_config.sd,
          "tac" => @old_config.tac,
          "protectionScheme" => @old_config.protectionScheme,
          "publicKey" => @old_config.publicKey,
          "publicKeyId" => @old_config.publicKeyId,
          "routingIndicator" => @old_config.routingIndicator,
          "enabled" => @old_config.enabled,
          "count" => @old_config.count,
          "initialMSISDN" => @old_config.initialMSISDN,
          "key" => @old_config.key,
          "op" => @old_config.op,
          "opType" => @old_config.opType,
          "type" => @old_config.type,
          "apn" => @old_config.apn,
          "emergency" => @old_config.emergency
        }
      end
    end
  end
end