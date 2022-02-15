require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

# CHAOS_MESH_VERSION = "v0.8.0"
# CHAOS_MESH_OFFLINE_DIR = "#{TarClient::TAR_REPOSITORY_DIR}/chaos-mesh_chaos-mesh"

desc "Install CNF Test Suite Cluster Tools"
task "install_cluster_tools" do |_, args|
  Log.info { "install_cluster_tools" }
  ClusterTools.install
end

desc "Uninstall CNF Test Suite Cluster Tools"
task "uninstall_cluster_tools" do |_, args|
  ClusterTools.uninstall
end
