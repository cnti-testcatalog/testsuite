require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"


module Dockerd
  def self.install
    Log.info { "Install dockerd from manifest" }
    KubectlClient::Apply.file(manifest_file, namespace: TESTSUITE_NAMESPACE)
    wait_for_install
  end

  def self.wait_for_install
    Log.info { "Wait for dockerd install" }
    KubectlClient::Get.resource_wait_for_install("Pod", "dockerd", wait_count: wait_count, namespace: TESTSUITE_NAMESPACE)
  end

  def self.uninstall
    Log.info { "Uninstall dockerd from manifest" }
    KubectlClient::Delete.file(manifest_file, namespace: TESTSUITE_NAMESPACE)
  end

  def self.manifest_file
    manifest_path = "./#{TOOLS_DIR}/dockerd-manifest.yml"
    unless File.exists?(manifest_path)
      File.write(manifest_path, DOCKERD_MANIFEST)
    end
    manifest_path
  end
end


desc "The dockerd tool is used to run docker commands against the cluster."
task "install_dockerd" do |_, args|
  Log.for("verbose").info { "install_dockerd" } if check_verbose(args)
  install_status = Dockerd.install
  unless install_status
    Log.error { "Dockerd_Install failed.".colorize(:red) }
  end
  Log.info { "Dockerd_Install status: #{install_status}" }
end

desc "Uninstall dockerd"
task "uninstall_dockerd" do |_, args|
  Dockerd.uninstall
end
