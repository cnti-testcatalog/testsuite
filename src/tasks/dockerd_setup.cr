require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "The dockerd tool is used to run docker commands against the cluster."
task "install_dockerd" do |_, args|
  VERBOSE_LOGGING.info "install_dockerd" if check_verbose(args)
  #TODO used process command to remove command line noise
  # install_dockerd = `kubectl create -f #{TOOLS_DIR}/dockerd/manifest.yml`
  status = Process.run("kubectl create -f #{TOOLS_DIR}/dockerd/manifest.yml",
                                shell: true,
                                output: install_dockerd = IO::Memory.new,
                                error: stderr = IO::Memory.new).success?
  LOGGING.info "Dockerd_Install output: #{install_dockerd.to_s}"
  LOGGING.info "Dockerd_Install stderr: #{stderr.to_s}"
  LOGGING.info "Dockerd_Install status: #{status}"
  if status
    status = KubectlClient::Get.resource_wait_for_install("Pod", "dockerd")
  else
    LOGGING.error "Dockerd_Install failed: #{stderr.to_s}".colorize(:red)
  end
  LOGGING.info "Dockerd_Install status: #{status}"
  status
end

desc "Uninstall dockerd"
task "uninstall_dockerd" do |_, args|
  VERBOSE_LOGGING.info "uninstall_dockerd" if check_verbose(args)
  delete_dockerd = `kubectl delete -f #{TOOLS_DIR}/dockerd/manifest.yml`
  LOGGING.debug "Dockerd_uninstall: #{delete_dockerd}"
end

