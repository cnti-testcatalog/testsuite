require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

# CHAOS_MESH_VERSION = "v0.8.0"
# CHAOS_MESH_OFFLINE_DIR = "#{TarClient::TAR_REPOSITORY_DIR}/chaos-mesh_chaos-mesh"

desc "Install CNF Test Suite CRI Tools"
task "install_cri_tools" do |_, args|
  File.write("cri_tools.yml", CRI_TOOLS)
  KubectlClient::Apply.file("cri_tools.yml")
  pod_ready = ""
  pod_ready_timeout = 45
  until (pod_ready == "true" || pod_ready_timeout == 0)
    pod_ready = KubectlClient::Get.pod_status("cri-tools").split(",")[2]
    Log.info { "Pod Ready Status: #{pod_ready}" }
    sleep 1
    pod_ready_timeout = pod_ready_timeout - 1
  end
  cri_tools_pod = KubectlClient::Get.pod_status("cri-tools").split(",")[0]
  Log.debug { "cri_tools_pod: #{cri_tools_pod}" }
end

desc "Uninstall CNF Test Suite CRI Tools"
task "uninstall_cri_tools" do |_, args|
  KubectlClient::Delete.file("cri_tools.yml")
end

module CRIToolsSetup
  def self.cri_tools_pod
    KubectlClient::Get.pod_status("cri-tools").split(",")[0]
  end
end
