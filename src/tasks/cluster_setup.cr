require "sam"
require "file_utils"
require "colorize"
require "cluster_tools"
require "totem"
require "./utils/utils.cr"

# CHAOS_MESH_VERSION = "v0.8.0"
# CHAOS_MESH_OFFLINE_DIR = "#{TarClient::TAR_REPOSITORY_DIR}/chaos-mesh_chaos-mesh"

desc "Install CNF Test Suite Cluster Tools"
task "install_cluster_tools" do |_, args|
  begin
    ClusterTools.install
  rescue e : ClusterTools::NamespaceDoesNotExistException 
    Log.info { "#{e.message}" }
    puts "Please run: cnf-testsuite setup"
  end
end

desc "Uninstall CNF Test Suite Cluster Tools"
task "uninstall_cluster_tools" do |_, args|
  begin
    ClusterTools.uninstall
  rescue e : ClusterTools::NamespaceDoesNotExistException
    Log.info { "#{e.message}" }
    puts "Please run: cnf-testsuite setup"
  end
end
