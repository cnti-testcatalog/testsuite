require "totem"
require "colorize"
require "./types/cnf_conformance_yml_type.cr"
require "./helm.cr"
require "uuid"
require "./points.cr"
require "./task.cr"

module CNFManager 
  module GenerateConfig
    def self.install_method_by_config_src(config_src : String)
      helm_chart_file = "#{config_src}/#{CHART_YAML}"
      LOGGING.debug "potential helm_chart_file: #{helm_chart_file}"

      if !Dir.exists?(config_src) 
        :helm_chart
      elsif File.exists?(helm_chart_file)
        :helm_directory
      elsif KubectlClient::Apply.validate(config_src)
        :manifest_directory
      else
        puts "Error: #{config_src} is neither a helm_chart, helm_directory, or manifest_directory.".colorize(:red)
        exit 1
      end
    end

    def self.export_manifest(config_src, output_file="./cnf-testsuite.yml")

      generate_initial_conformance_yml(config_src, output_file)
      CNFManager.generate_and_set_release_name(output_file)
      config = CNFManager.parsed_config_file(output_file)
      release_name = optional_key_as_string(config, "release_name")
      if install_method_by_config_src(config_src) == :manifest_directory
        template_ymls = Helm::Manifest.manifest_ymls_from_file_list(Helm::Manifest.manifest_file_list( config_src))
      else
        Helm.generate_manifest_from_templates(release_name,
                                              config_src)
        template_ymls = Helm::Manifest.parse_manifest_as_ymls()
      end
      resource_ymls = Helm.all_workload_resources(template_ymls)
      resource_ymls
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
            update_yml(output_file, "container_names", container_names)
          end
        end
        # resp
      end
    end

    # Please don't indent this.
    def self.conformance_yml_template
      <<-TEMPLATE
      release_name:
      {{ install_key }} 
      TEMPLATE
    end

    def self.generate_initial_conformance_yml(config_src, config_yml_path="./cnf-testsuite.yml")
      if !File.exists?(config_yml_path)
        case install_method_by_config_src(config_src) 
        when :helm_chart
          conformance_yml_template_resp = Crinja.render(conformance_yml_template, { "install_key" => "helm_chart: #{config_src}"})
        when :helm_directory
          conformance_yml_template_resp = Crinja.render(conformance_yml_template, { "install_key" => "helm_directory: #{config_src}"})
        when :manifest_directory
          conformance_yml_template_resp = Crinja.render(conformance_yml_template, { "install_key" => "manifest_directory: #{config_src}"})
        else
          puts "Error: #{config_src} is neither a helm_chart, helm_directory, or manifest_directory.".colorize(:red)
          exit 1
        end
        write_template= `echo "#{conformance_yml_template_resp}" > "#{config_yml_path}"`
      else
        LOGGING.error "#{config_yml_path} already exists"
      end
    end
  end
end

