module Dockerd
  def self.install
    Log.info { "Install dockerd from manifest" }
    KubectlClient::Apply.file(manifest_file, namespace: TESTSUITE_NAMESPACE)
    wait_for_install
  end

  def self.wait_for_install
    Log.info { "Wait for dockerd install" }
    KubectlClient::Get.resource_wait_for_install("Pod", "dockerd", wait_count: 180, namespace: TESTSUITE_NAMESPACE)
  end

  def self.uninstall
    Log.info { "Uninstall dockerd from manifest" }
    KubectlClient::Delete.file(manifest_file, namespace: TESTSUITE_NAMESPACE)
  end

  def self.exec(cli, force_output : Bool = false)
    KubectlClient.exec("dockerd -t -- #{cli}", namespace: TESTSUITE_NAMESPACE, force_output: force_output)
  end

  def self.manifest_file
    manifest_path = "./#{TOOLS_DIR}/dockerd-manifest.yml"
    unless File.exists?(manifest_path)
      File.write(manifest_path, DOCKERD_MANIFEST)
    end
    manifest_path
  end
end