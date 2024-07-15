require "totem"
require "colorize"
require "./types/cnf_testsuite_yml_type.cr"
require "helm"
require "uuid"
require "./points.cr"
require "./task.cr"

module CNFManager 

  class Config
    def initialize(cnf_config)
      @cnf_config = cnf_config
    end
    #when addeding to this you must add to task.cr's CNFManager::Config.new(
    property cnf_config : NamedTuple(destination_cnf_dir: String,
                                     source_cnf_file: String,
                                     source_cnf_dir: String,
                                     yml_file_path: String,
                                     install_method: Tuple(Helm::InstallMethod, String),
                                     manifest_directory: String,
                                     helm_directory: String, 
                                     source_helm_directory: String, 
                                     helm_chart_path: String, 
                                     manifest_file_path: String,
                                     release_name: String,
                                     service_name:  String,
                                     helm_repository: NamedTuple(name:  String, repo_url:  String) | Nil,
                                     helm_chart:  String,
                                     helm_values:  String,
                                     helm_install_namespace: String,
                                     rolling_update_tag: String,
                                     container_names: Array(Hash(String, String )) | Nil,
                                     white_list_container_names: Array(String),
                                     docker_insecure_registries: Array(String) | Nil,
                                     #todo change this to an array of labels that capture all of 5g core nodes
                                     amf_label: String,
                                     smf_label: String,
                                     upf_label: String,
                                     ric_label: String,
                                     fiveG_core: NamedTuple(amf_service_name: String,
                                                           mmc: String,
                                                           mnc: String,
                                                           sst: String,
                                                           sd: String,
                                                           tac: String,
                                                           protectionScheme: String,
                                                           publicKey: String,
                                                           publicKeyId: String,
                                                           routingIndicator: String,
                                                           enabled: String,
                                                           count: String,
                                                           initialMSISDN: String,
                                                           key: String,
                                                           op: String,
                                                           opType: String,
                                                           type: String,
                                                           apn: String,
                                                           emergency: String
                                                          ),
                                     image_registry_fqdns: Hash(String, String ) | Nil)

    def self.parse_config_yml(config_yml_path : String) : CNFManager::Config
      LOGGING.debug "parse_config_yml config_yml_path: #{config_yml_path}"
      yml_file = CNFManager.ensure_cnf_testsuite_yml_path(config_yml_path)
      #TODO modify the destination testsuite yml instead of the source testsuite yml 
      # (especially in the case of the release manager).  Then reread the destination config
      # TODO for cleanup, read source, then find destination and use release name from destination config
      # TODO alternatively use a CRD to save the release name

      CNFManager.generate_and_set_release_name(config_yml_path)
      config = CNFManager.parsed_config_file(yml_file)
      install_method = CNFManager.cnf_installation_method(config)

      destination_cnf_dir = CNFManager.cnf_destination_dir(yml_file)

      yml_file_path = CNFManager.ensure_cnf_testsuite_dir(config_yml_path)
      source_cnf_file = yml_file
      source_cnf_dir = yml_file_path
      manifest_directory = optional_key_as_string(config, "manifest_directory")
      if config["helm_repository"]?
          helm_repository = config["helm_repository"].as_h
        helm_repo_name = optional_key_as_string(helm_repository, "name")
        helm_repo_url = optional_key_as_string(helm_repository, "repo_url")
      else
        helm_repo_name = ""
        helm_repo_url = ""
      end
      helm_chart = optional_key_as_string(config, "helm_chart")
      helm_values = optional_key_as_string(config, "helm_values")
      release_name = optional_key_as_string(config, "release_name")
      service_name = optional_key_as_string(config, "service_name")
      helm_directory = optional_key_as_string(config, "helm_directory")
      source_helm_directory = optional_key_as_string(config, "helm_directory")
      helm_install_namespace = optional_key_as_string(config, "helm_install_namespace")
      if config["enabled"]?
          core_enabled = config["enabled"].as_bool.to_s
      else
        core_enabled = "" 
      end
      if config["emergency"]?
          core_emergency = config["emergency"].as_bool.to_s
      else
        core_emergency = "" 
      end
      if config["sd"]?
          core_sd = config["sd"].as_s
      else
        core_sd = "" 
      end
      fiveG_core = {amf_service_name: optional_key_as_string(config, "amf_service_name"),
      mmc: optional_key_as_string(config, "mmc"),
      mnc:  optional_key_as_string(config, "mnc"),
      sst:  optional_key_as_string(config, "sst"),
      sd:  core_sd,
      tac:  optional_key_as_string(config, "tac"),
      protectionScheme:  optional_key_as_string(config, "protectionScheme"),
      publicKey:  optional_key_as_string(config, "publicKey"),
      publicKeyId:  optional_key_as_string(config, "publicKeyId"),
      routingIndicator:  optional_key_as_string(config, "routingIndicator"),
      enabled:  core_enabled,
      count:  optional_key_as_string(config, "count"),
      initialMSISDN:  optional_key_as_string(config, "initialMSISDN"),
      key:  optional_key_as_string(config, "key"),
      op:  optional_key_as_string(config, "op"),
      opType:  optional_key_as_string(config, "opType"),
      type:  optional_key_as_string(config, "type"),
      apn:  optional_key_as_string(config, "apn"),
      emergency:  core_emergency,
      }
      core  = optional_key_as_string(config, "amf_label")
      smf  = optional_key_as_string(config, "smf_label")
      upf  = optional_key_as_string(config, "upf_label")
      ric = optional_key_as_string(config, "ric_label")
      if helm_directory.empty?
        working_chart_directory = "exported_chart"
        Log.info { "USING EXPORTED CHART PATH" } 
      else
        # todo separate parameters from helm directory
        # TODO Fix bug with helm_directory for arguments, it creates an invalid path
        # # we don't handle arguments anymore
        # helm_directory = source_helm_directory.split("/")[0] + " " + source_helm_directory.split(" ")[1..-1].join(" ")
        # helm_directory = optional_key_as_string(config, "helm_directory")
        working_chart_directory = helm_directory
        Log.info { "NOT USING EXPORTED CHART PATH" } 
      end
      helm_chart_path = destination_cnf_dir + "/" + CNFManager.sandbox_helm_directory(working_chart_directory)
      helm_chart_path = Path[helm_chart_path].expand.to_s
      manifest_file_path = destination_cnf_dir + "/" + "temp_template.yml"
      white_list_container_names = optional_key_as_string(config, "allowlist_helm_chart_container_names")
      if config["allowlist_helm_chart_container_names"]?
        white_list_container_names = config["allowlist_helm_chart_container_names"].as_a.map do |c|
          "#{c.as_s?}"
        end
      else
        white_list_container_names = [] of String
      end
      if config["container_names"]?
        container_names_totem = config["container_names"]
        container_names = container_names_totem.as_a.map do |container|
          {"name" => optional_key_as_string(container, "name"),
           "rolling_update_test_tag" => optional_key_as_string(container, "rolling_update_test_tag"),
           "rolling_downgrade_test_tag" => optional_key_as_string(container, "rolling_downgrade_test_tag"),
           "rolling_version_change_test_tag" => optional_key_as_string(container, "rolling_version_change_test_tag"),
           "rollback_from_tag" => optional_key_as_string(container, "rollback_from_tag"),
           }
        end
      else
        container_names = [{"name" => "",
         "rolling_update_test_tag" => "",
         "rolling_downgrade_test_tag" => "",
         "rolling_version_change_test_tag" => "",
         "rollback_from_tag" => "",
         }]
      end

      docker_insecure_registries = [] of String
      if config["docker_insecure_registries"]? && !config["docker_insecure_registries"].nil?
        docker_insecure_registries = config["docker_insecure_registries"].as_a.map do |c|
          "#{c.as_s?}"
        end
      end

      image_registry_fqdns = Hash(String, String).new
      if config["image_registry_fqdns"]? && !config["image_registry_fqdns"].nil?
        config["image_registry_fqdns"].as_h.each do |key, value|
          image_registry_fqdns[key] = value.as_s
        end
      end

      # if you change this, change instantiation in task.cr/single_task_runner as well
      new({ destination_cnf_dir: destination_cnf_dir,
                               source_cnf_file: source_cnf_file,
                               source_cnf_dir: source_cnf_dir,
                               yml_file_path: yml_file_path,
                               install_method: install_method,
                               manifest_directory: manifest_directory,
                               helm_directory: helm_directory, 
                               source_helm_directory: source_helm_directory, 
                               helm_chart_path: helm_chart_path, 
                               manifest_file_path: manifest_file_path,
                               release_name: release_name,
                               service_name: service_name,
                               helm_repository: {name: helm_repo_name, repo_url: helm_repo_url},
                               helm_chart: helm_chart,
                               helm_values: helm_values,
                               helm_install_namespace: helm_install_namespace,
                               rolling_update_tag: "",
                               container_names: container_names,
                               white_list_container_names: white_list_container_names,
                               docker_insecure_registries: docker_insecure_registries,
                               amf_label: core,
                               smf_label: smf,
                               upf_label: upf,
                               ric_label: ric,
                               fiveG_core: fiveG_core,
                               image_registry_fqdns: image_registry_fqdns,})

    end
    def self.install_method_by_config_file(config_file) : Helm::InstallMethod
      LOGGING.info "install_data_by_config_file"
      config = CNFManager.parsed_config_file(config_file)
      sandbox_config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file)) 
      install_method = CNFManager.cnf_installation_method(config)
      install_method[0]
    end
    def self.config_src_by_config_file(config_file) : String
      LOGGING.info "install_data_by_config_file"
      config = CNFManager.parsed_config_file(config_file)
      sandbox_config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file)) 
      install_method = CNFManager.cnf_installation_method(config)
      install_method[1]
    end
    def self.release_name_by_config_file(config_file) : String
      LOGGING.info "release_name_by_config_file"
      config = CNFManager.parsed_config_file(config_file)
      sandbox_config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file)) 
      release_name = sandbox_config.cnf_config[:release_name]
    end
  end
end
