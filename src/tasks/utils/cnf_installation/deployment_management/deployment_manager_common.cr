module CNFInstall
  abstract class DeploymentManager
    property deployment_name

    abstract def install
    abstract def uninstall
    abstract def generate_manifest
    
    def initialize(deployment_name)
      @deployment_name = deployment_name
    end
  end

  
end