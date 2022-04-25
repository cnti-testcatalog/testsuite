require "totem"
require "colorize"
require "./types/cnf_testsuite_yml_type.cr"
require "helm"
require "uuid"
require "./points.cr"
require "./task.cr"

module CNFManager 

  class Config
    def initialize(cnf_config, airgapped=false)
      @cnf_config = cnf_config 
      @airgapped = airgapped
    end
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
                                     git_clone_url: String,
                                     release_name: String,
                                     service_name:  String,
                                     docker_repository: String,
                                     helm_repository: NamedTuple(name:  String, 
                                                                 repo_url:  String) | Nil,
                                     helm_chart:  String,
                                     helm_chart_container_name: String,
                                     rolling_update_tag: String,
                                     container_names: Array(Hash(String, String )) | Nil,
                                     white_list_container_names: Array(String)) 

    def self.parse_config_yml(config_yml_path : String, airgapped=false, generate_tar_mode=false) : CNFManager::Config
      LOGGING.debug "parse_config_yml config_yml_path: #{config_yml_path}"
      LOGGING.info "airgapped: #{airgapped}"
      LOGGING.info "generate_tar_mode: #{generate_tar_mode}"
      yml_file = CNFManager.ensure_cnf_testsuite_yml_path(config_yml_path)
      #TODO modify the destination testsuite yml instead of the source testsuite yml 
      # (especially in the case of the release manager).  Then reread the destination config
      # TODO for cleanup, read source, then find destination and use release name from destination config
      # TODO alternatively use a CRD to save the release name

      CNFManager.generate_and_set_release_name(config_yml_path, airgapped, generate_tar_mode)
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
      release_name = optional_key_as_string(config, "release_name")
      service_name = optional_key_as_string(config, "service_name")
      helm_directory = optional_key_as_string(config, "helm_directory")
      source_helm_directory = optional_key_as_string(config, "helm_directory")
      git_clone_url = optional_key_as_string(config, "git_clone_url")
      docker_repository = optional_key_as_string(config, "docker_repository")
      helm_install_namespace = optional_key_as_string(config, "helm_install_namespace")
      if helm_directory.empty?
        working_chart_directory = "exported_chart"
        Log.info { "USING EXPORTED CHART PATH" } 
      else
        # todo separate parameters from helm directory
        # TODO Fix bug with helm_directory for arguments, it creates an invalid path
        helm_directory = source_helm_directory.split("/")[0] + " " + source_helm_directory.split(" ")[1..-1].join(" ")
        # helm_directory = optional_key_as_string(config, "helm_directory")
        working_chart_directory = helm_directory
        Log.info { "NOT USING EXPORTED CHART PATH" } 
      end
      helm_chart_path = destination_cnf_dir + "/" + working_chart_directory 
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
                               git_clone_url: git_clone_url,
                               release_name: release_name,
                               service_name: service_name,
                               docker_repository: docker_repository,
                               helm_install_namespace: helm_install_namespace,
                               helm_repository: {name: helm_repo_name, repo_url: helm_repo_url},
                               helm_chart: helm_chart,
                               helm_chart_container_name: "",
                               rolling_update_tag: "",
                               container_names: container_names,
                               white_list_container_names: white_list_container_names })

    end
    def self.install_method_by_config_file(config_file) : Helm::InstallMethod
      LOGGING.info "install_data_by_config_file"
      config = CNFManager.parsed_config_file(config_file)
      sandbox_config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file), airgapped: true, generate_tar_mode: false) 
      install_method = CNFManager.cnf_installation_method(config)
      install_method[0]
    end
    def self.config_src_by_config_file(config_file) : String
      LOGGING.info "install_data_by_config_file"
      config = CNFManager.parsed_config_file(config_file)
      sandbox_config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file), airgapped: true, generate_tar_mode: false) 
      install_method = CNFManager.cnf_installation_method(config)
      install_method[1]
    end
    def self.release_name_by_config_file(config_file) : String
      LOGGING.info "release_name_by_config_file"
      config = CNFManager.parsed_config_file(config_file)
      sandbox_config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file), airgapped: true, generate_tar_mode: false) 
      release_name = sandbox_config.cnf_config[:release_name]
    end
  end
end
