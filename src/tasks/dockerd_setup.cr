require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"


desc "The dockerd tool is used to run docker commands against the cluster."
task "install_dockerd" do |_, args|
  Log.for("verbose").info { "install_dockerd" } if check_verbose(args)
  resp = KubectlClient::Apply.file(dockerd_filename)
  if resp
    status = check_dockerd(180)
  end
  unless status
    Log.error { "Dockerd_Install failed.".colorize(:red) }
  end
  Log.info { "Dockerd_Install status: #{status}" }
  status
end

desc "Uninstall dockerd"
task "uninstall_dockerd" do |_, args|
  Log.info { "uninstall_dockerd" }
  KubectlClient::Delete.file(dockerd_filename)
end

def dockerd_filename
  manifest_path = "./#{TOOLS_DIR}/dockerd-manifest.yml"
  File.write(manifest_path, DOCKERD_MANIFEST)
  manifest_path
end

### Checks to see if dockerd is already installed.  Alternatively
### can be used to wait for dockerd is installed by passing a higher wait_count)
def check_dockerd(wait_count = 1) 
  Log.info { "check_dockerd" }
  KubectlClient::Get.resource_wait_for_install("Pod", "dockerd", wait_count: wait_count)
  # pod_ready = ""
  # pod_ready_timeout = 25 
  # until (pod_ready == "true" || pod_ready_timeout == 0)
  #   pod_ready = KubectlClient::Get.pod_status("dockerd").split(",")[2]
  #   puts "Pod Ready Status: #{pod_ready}"
  #   sleep 1
  #   pod_ready_timeout = pod_ready_timeout - 1
  # end
  # if  (pod_ready && !pod_ready.empty? && pod_ready == "true") 
  #   true
  # else
  #   false
  # end
end
