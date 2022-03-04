module Kyverno
  VERSION = "1.5.0"

  def self.install
    result = KubectlClient::Apply.file(manifest_url)
    return false if !result[:status].success?

    download_policies_repo
    KubectlClient::Get.resource_wait_for_install("deployment", "kyverno", 180, "kyverno")
  end

  def self.uninstall
    result = KubectlClient::Delete.file(manifest_url)
    delete_policies_repo
    KubectlClient::Get.resource_wait_for_uninstall("deployment", "kyverno", 180, "kyverno")
  end

  def self.manifest_url
    "https://raw.githubusercontent.com/kyverno/kyverno/v#{VERSION}/definitions/release/install.yaml"
  end

  def self.policies_repo_path
    "#{tools_path}/kyverno-policies"
  end

  def self.download_policies_repo
    url = "https://github.com/kyverno/kyverno.git"
    result = GitClient.clone("#{url} #{policies_repo_path}")
    result[:status].success?
  end

  def self.delete_policies_repo
    FileUtils.rm_rf(policies_repo_path)
  end
end
