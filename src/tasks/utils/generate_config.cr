require "totem"
require "colorize"
require "./types/cnf_testsuite_yml_type.cr"
require "helm"
require "uuid"
require "./points.cr"
require "./task.cr"

module CNFManager 
  module GenerateConfig
    def self.export_manifest(config_src, output_file="./cnf-testsuite.yml")
      LOGGING.info "export_manifest"
      LOGGING.info "export_manifest config_src: #{config_src}"
      generate_initial_testsuite_yml(config_src, output_file)
      CNFManager.generate_and_set_release_name(output_file, src_mode: true)
      config = CNFManager.parsed_config_file(output_file)
      release_name = optional_key_as_string(config, "release_name")
      install_method = CNFManager.install_method_by_config_src(config_src)
      LOGGING.info "install_method: #{install_method}"
      if install_method == Helm::InstallMethod::ManifestDirectory
        template_ymls = Helm::Manifest.manifest_ymls_from_file_list(Helm::Manifest.manifest_file_list( config_src))
      else
        # todo if success false, raise error
        Helm.generate_manifest_from_templates(release_name,
                                              config_src)
        template_ymls = Helm::Manifest.parse_manifest_as_ymls()
      end
      resource_ymls = Helm.all_workload_resources(template_ymls)
      resource_ymls
    end

    #get list of image:tags from helm chart/helm directory/manifest file
    #note: config_src must be an absolute path if a directory, todo: make this more resilient
    def self.images_from_config_src(config_src)
      LOGGING.info "images_from_config_src"
      #return container image name/tag
      ret_containers = [] of NamedTuple(container_name: String, image_name: String, tag: String) 
      resource_ymls = CNFManager::GenerateConfig.export_manifest(config_src)
      resource_resp = resource_ymls.map do | resource |
        LOGGING.info "gen config resource: #{resource}"
        unless resource["kind"].as_s.downcase == "service" ## services have no containers
          containers = Helm::Manifest.manifest_containers(resource)

          LOGGING.info "containers: #{containers}"
          container_name = containers.as_a[0].as_h["name"].as_s if containers
          if containers
            container_names = containers.as_a.map do |container|
              LOGGING.debug "container: #{container}"
              container_name = container.as_h["name"].as_s 
              image_name = container.as_h["image"].as_s.split(":")[0]
              if container.as_h["image"].as_s.split(":").size > 1
                tag = container.as_h["image"].as_s.split(":")[1]
              else
                tag = "latest"
              end
              ret_containers << {container_name: container_name, 
                                 image_name: image_name, 
                                 tag: tag}
              LOGGING.debug "ret_containers: #{ret_containers}"
            end
          end
        end
      end
      ret_containers
    end

    def self.generate_config(config_src, output_file="./cnf-testsuite.yml")
      resource_ymls = CNFManager::GenerateConfig.export_manifest(config_src, output_file)
      resource_resp = resource_ymls.map do | resource |
        LOGGING.info "gen config resource: #{resource}"
        unless resource["kind"].as_s.downcase == "service" ## services have no containers
          containers = Helm::Manifest.manifest_containers(resource)

          LOGGING.info "containers: #{containers}"
          container_name = containers.as_a[0].as_h["name"].as_s if containers
          if containers
            container_names = containers.as_a.map { |container|
              LOGGING.debug "container: #{container}"
              if container.as_h["image"].as_s.split(":").size > 1
                rolling_update_test_tag = container.as_h["image"].as_s.split(":")[1]
              else
                rolling_update_test_tag = ""
              end
# don't mess with the indentation here
  container_names_template = <<-TEMPLATE

   - name: #{container.as_h["name"].as_s} 
     rolling_update_test_tag: #{rolling_update_test_tag}
     rolling_downgrade_test_tag: #{rolling_update_test_tag}
     rolling_version_change_test_tag: #{rolling_update_test_tag}
     rollback_from_tag: #{rolling_update_test_tag} 
  TEMPLATE
            }.join("")
            # Don't add container_names to yml. This isn't needed until the rolling update tests are added to the cert.
            # update_yml(output_file, "container_names", container_names)
          end
        end
        # resp
      end
    end

    def self.generate_initial_testsuite_yml(config_src, config_yml_path="./cnf-testsuite.yml")
      if !File.exists?(config_yml_path)
        case CNFManager.install_method_by_config_src(config_src) 
        when Helm::InstallMethod::HelmChart
          testsuite_yml_template_resp = TestSuiteYmlTemplate.new("helm_chart: #{config_src}").to_s
        when Helm::InstallMethod::HelmDirectory
          testsuite_yml_template_resp = TestSuiteYmlTemplate.new("helm_directory: #{config_src}").to_s
        when Helm::InstallMethod::ManifestDirectory
          testsuite_yml_template_resp = TestSuiteYmlTemplate.new("manifest_directory: #{config_src}").to_s
        else
          puts "Error: #{config_src} is neither a helm_chart, helm_directory, or manifest_directory.".colorize(:red)
          exit 1
        end
        File.write(config_yml_path, testsuite_yml_template_resp)
      else
        LOGGING.error "#{config_yml_path} already exists"
      end
    end
  end
end

class TestSuiteYmlTemplate
  def initialize(@install_key : String)
  end

  ECR.def_to_s("src/templates/testsuite_template.yml.ecr")
end
