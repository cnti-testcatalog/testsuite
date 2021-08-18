require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"


desc "The dockerd tool is used to run docker commands against the cluster."
task "install_dockerd" do |_, args|
  Log.for("verbose").info { "install_dockerd" } if check_verbose(args)
  result = KubectlClient::Apply.file(dockerd_filename)
  if result[:status].success?
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
  "./#{TOOLS_DIR}/dockerd/manifest.yml"
end

def dockerd_tempname
  "./#{TOOLS_DIR}/dockerd/manifest.tmp"
end

def dockerd_tempname_helper
  Log.info { "dockerd_tempname_helper" }
  Log.info { "Contents of #{TOOLS_DIR} before moving dockerd manifest to tempfile" }
  Log.info { "ls #{TOOLS_DIR}: #{Dir.children(TOOLS_DIR)}" }
  Log.info { "ls #{TOOLS_DIR}/dockerd: #{Dir.children("#{TOOLS_DIR}/dockerd")}" }
  FileUtils.mv(dockerd_filename, dockerd_tempname)
  Log.info { "Contents of #{TOOLS_DIR} after moving dockerd manifest to tempfile" }
  Log.info { "ls #{TOOLS_DIR}: #{Dir.children(TOOLS_DIR)}" }
  Log.info { "ls #{TOOLS_DIR}/dockerd: #{Dir.children("#{TOOLS_DIR}/dockerd")}" }
end

def dockerd_name_helper
  Log.info { "dockerd_name_helper" }
  Log.info { "Contents of #{TOOLS_DIR} before moving dockerd manifest from tempfile to it's place" }
  Log.info { "ls #{TOOLS_DIR}: #{Dir.children(TOOLS_DIR)}" }
  Log.info { "ls #{TOOLS_DIR}/dockerd: #{Dir.children("#{TOOLS_DIR}/dockerd")}" }
  FileUtils.mv(dockerd_tempname, dockerd_filename)
  Log.info { "Contents of #{TOOLS_DIR} after moving dockerd manifest from tempfile to it's place" }
  Log.info { "ls #{TOOLS_DIR}: #{Dir.children(TOOLS_DIR)}" }
  Log.info { "ls #{TOOLS_DIR}/dockerd: #{Dir.children("#{TOOLS_DIR}/dockerd")}" }
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
