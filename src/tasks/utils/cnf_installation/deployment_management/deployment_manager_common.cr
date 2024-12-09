module CNFInstall
  abstract class DeploymentManager
    property deployment_name : String,
             installation_priority : Int32

    abstract def install
    abstract def uninstall
    abstract def generate_manifest
    
    def initialize(deployment_name, installation_priority)
      @deployment_name = deployment_name
      @installation_priority = installation_priority
    end
  end

  
end