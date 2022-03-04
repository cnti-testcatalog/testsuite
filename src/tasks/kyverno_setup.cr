require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Install Kyverno"
task "install_kyverno", ["download_kyverno_policies"] do |_, args|
  kyverno_version="1.5.0"
  url = "https://raw.githubusercontent.com/kyverno/kyverno/v#{kyverno_version}/definitions/release/install.yaml"
  result = KubectlClient::Apply.file(url)
  is_ready = KubectlClient::Get.resource_wait_for_install("deployment", "kyverno", 180, "kyverno")

  if is_ready
    stdout_success "Kyverno successfully installed"
  else
    stdout_success "Kyverno installation failed"
  end
end

desc "Download Kyverno best practices policies"
task "download_kyverno_policies" do |_, args|
  kyverno_version="1.5.0"
  url = "https://github.com/kyverno/kyverno.git"
  clone_path = "#{tools_path}/kyverno-policies"
  result = GitClient.clone("#{url} #{clone_path}")

  if result[:status].success?
    stdout_success "Kyverno best practices policies downloaded successfully"
  else
    stdout_success "Failed to download Kyverno best practices policies"
  end
end

desc "Uninstall Kyverno"
task "uninstall_kyverno" do |_, args|
  kyverno_version="1.5.0"
  url = "https://raw.githubusercontent.com/kyverno/kyverno/v#{kyverno_version}/definitions/release/install.yaml"
  result = KubectlClient::Delete.file(url)

  if !result[:status].success?
    stdout_failure "Kyverno could not be uninstalled."
  else
    stdout_success "Kyverno was uninstalled successfully"
  end
end

desc "Delete all cluster policies and policy reports in all namespaces"
task "cleanup_policies" do |_, args|
  result = KubectlClient::Get.delete_all_clusterpolicies_and_policyreports_allnamespaces()

  if !result[:status].success?
    stdout_failure "Kyverno policies could not be uninstalled. Please uninstall manually"
  else
    stdout_success "Kyverno policies were uninstalled successfully"
  end
end
