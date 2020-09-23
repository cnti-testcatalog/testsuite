CNFSingleton = CNFGlobals.new
class CNFGlobals
  CNF_DIR = "cnfs"
  @helm: String?
  # Get helm directory
  def helm 
    @helm ||= global_helm_installed? ? "helm" : CNFManager.local_helm_path
  end
end


