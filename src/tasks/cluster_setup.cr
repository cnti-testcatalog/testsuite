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
  cli_hash = CNFManager.sample_setup_cli_args(args)
  input_file =  cli_hash[:input_file]

  unless input_file && !input_file.empty?
    ClusterTools.install
  end
end

desc "Uninstall CNF Test Suite Cluster Tools"
task "uninstall_cluster_tools" do |_, args|
  KubectlClient::Delete.file("cluster_tools.yml")
  ClusterTools.uninstall
end

module ClusterToolsSetup
  def self.cluster_tools_pod
    KubectlClient::Get.pod_status("cluster-tools").split(",")[0]
  end
end

