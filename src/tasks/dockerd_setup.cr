require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "The dockerd tool is used to run docker commands against the cluster."
task "install_dockerd" do |_, args|
  VERBOSE_LOGGING.info "install_dockerd" if check_verbose(args)
  #TODO used process command to remove command line noise
  install_dockerd = `kubectl create -f #{TOOLS_DIR}/dockerd/manifest.yml`
  LOGGING.debug "Dockerd_Install: #{install_dockerd}"
  KubectlClient::Get.resource_wait_for_install("Pod", "dockerd")
  sleep 2.0
end

desc "Uninstall dockerd"
task "uninstall_dockerd" do |_, args|
  VERBOSE_LOGGING.info "uninstall_dockerd" if check_verbose(args)
  delete_dockerd = `kubectl delete -f #{TOOLS_DIR}/dockerd/manifest.yml`
  LOGGING.debug "Dockerd_uninstall: #{delete_dockerd}"
end

