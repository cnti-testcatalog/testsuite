require "json"

# NOTE: want add/change a bunch of new fields and don't want to figure out how to do it manually?
# 
# in a script or using icr
# 
# require "./src/tasks/utils/cnf_manager.cr"
# config = cnf_conformance_yml
# config.settings.to_json
# 
# now take that json here https://app.quicktype.io/?share=Tfokny8vUaAeJ7XDOTSo
# and generate new types

# https://crystal-lang.org/api/0.34.0/JSON/Serializable.html
class CnfConformanceYmlType
  include JSON::Serializable
  include JSON::Serializable::Unmapped

  macro methods
    {{ @type.methods.map &.name.stringify }}
  end

  property helm_directory : String

  property git_clone_url : String?

  property install_script : String?

  property service_name : String?

  property release_name : String

  property docker_repository : String?

  property deployment_name : String

  property deployment_label : String

  property application_deployment_names : Array(String)

  property helm_repository : HelmRepositoryType?

  property helm_chart : String?

  property helm_chart_container_name : String?

  property rolling_update_tag : String?
  property rolling_downgrade_tag : String?
  property rolling_version_change_tag : String?

  property white_list_helm_chart_container_names : Array(String)
end

class HelmRepositoryType
  include JSON::Serializable
  include JSON::Serializable::Unmapped

  property name : String

  property repo_url : String
end
