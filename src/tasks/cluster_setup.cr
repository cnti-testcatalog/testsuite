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
  # File.write("cluster_tools.yml", CLUSTER_TOOLS)
  # KubectlClient::Apply.file("cluster_tools.yml")
  # ClusterTools.wait_for_cluster_tools
  # pod_ready = ""
  # pod_ready_timeout = 45
  # until (pod_ready == "true" || pod_ready_timeout == 0)
  #   pod_ready = KubectlClient::Get.pod_status("cluster-tools").split(",")[2]
  #   Log.info { "Pod Ready Status: #{pod_ready}" }
  #   sleep 1
  #   pod_ready_timeout = pod_ready_timeout - 1
  # end
  # cluster_tools_pod = KubectlClient::Get.pod_status("cluster-tools").split(",")[0]
  # Log.debug { "cluster_tools_pod: #{cluster_tools_pod}" }
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

