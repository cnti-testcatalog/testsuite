require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"

module Helm

  # TODO change constants to named tuples
  # https://crystal-lang.org/reference/syntax_and_semantics/literals/named_tuple.html
  DEPLOYMENT="Deployment"
  SERVICE="Service"
  POD="Pod"

  def self.read_template_as_ymls(template_file_name)
    templates = File.read(template_file_name)
    split_template = templates.split("---")
    ymls = split_template.map { | template |
      YAML.parse(template)
      # compact seems to have problems with yaml::any
    }.reject{|x|x==nil}
    LOGGING.debug "read_template ymls: #{ymls}"
    ymls
  end

  # Use helm to apply the helm values file to the helm chart templates to create a complete manifest
  def self.generate_manifest_from_templates(release_name, helm_chart, output_file="cnfs/temp_template.yml")
    LOGGING.debug "generate_manifest_from_templates"
    helm = CNFSingleton.helm
    LOGGING.info "Helm::generate_manifest_from_templates command: #{helm} template #{release_name} #{helm_chart} > #{output_file}"
    template_resp = `#{helm} template #{release_name} #{helm_chart} > #{output_file}`
    LOGGING.info "template_resp: #{template_resp}"
    [$?.success?, output_file]
  end

  def self.workload_resource_by_kind(ymls, kind)
    LOGGING.info "workload_resource_by_kind kind: #{kind}"
    LOGGING.debug "workload_resource_by_kind ymls: #{ymls}"
    # resources = ymls.map do |yml|
      # yml.as_a.select{|x| x["kind"]?==kind}
    resources = ymls.select{|x| x["kind"]?==kind}
    # end
    LOGGING.debug "resources: #{resources}"
    resources
  end

  def self.workload_resource_names(resources)
    resource_names = resources.map do |x|
      x["metadata"]["name"]
    end
    LOGGING.debug "resource names: #{resource_names}"
    resource_names
  end

  # TODO loop through all files in directory of manifests

end 
