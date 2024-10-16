require "../config_versions/config_versions.cr"
require "./deployment_manager_common.cr"


module CNFInstall
  class ManifestDeploymentManager < DeploymentManager
    @manifest_config : ConfigV2::ManifestDirectoryConfig
    @manifest_directory_path : String

    def initialize(manifest_config)
      super(manifest_config.name)
      @manifest_config = manifest_config
      @manifest_directory_path = File.join(DEPLOYMENTS_DIR, @deployment_name, @manifest_config.manifest_directory)
    end

    def install()
      KubectlClient::Apply.file(@manifest_directory_path)
    end

    def uninstall()
      result = KubectlClient::Delete.file(@manifest_directory_path, wait: true)
      if result[:status].success?
        stdout_success "Successfully uninstalled manifest deployment \"#{@manifest_config.name}\""
      end
    end

    def generate_manifest()
    end
  end
end