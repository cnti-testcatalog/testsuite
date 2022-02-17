require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Install Kyverno"
task "install_kyverno" do |_, args|
  kyverno_version="1.5.0"
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  url = "https://raw.githubusercontent.com/kyverno/kyverno/v#{kyverno_version}/definitions/release/install.yaml"
#  url = "https://raw.githubusercontent.com/nsagark/nginx/main/install.yaml?token=AVOW2YXCWWYMYX7PFYJ6ZBLBU7ZQC"
  result = KubectlClient::Apply.file(url)

  if !result[:status].success?
    # fail and exit
  end

  is_ready = KubectlClient::Get.resource_wait_for_install("deployment", "kyverno", 180, "kyverno")
  if is_ready
    stdout_success "Kyverno successfully installed"
  end
end


desc "Uninstall Kyverno"
task "uninstall_kyverno" do |_, args|
  kyverno_version="1.5.0"
  stdout = IO::Memory.new
  stderr = IO::Memory.new
   url = "https://raw.githubusercontent.com/kyverno/kyverno/v#{kyverno_version}/definitions/release/install.yaml"
#   url = "https://raw.githubusercontent.com/nsagark/nginx/main/install.yaml?token=AVOW2YXCWWYMYX7PFYJ6ZBLBU7ZQC"
  result = KubectlClient::Delete.file(url)

  if !result[:status].success?
    stdout_failure "Kyverno could not uninstall correctly. Please uninstall manually"
  else
    stdout_success "Kyverno was uninstalled successfully"
  end
end

desc "Delete all cluster policies and policy reports in all namespaces"
task "cleanup_policies" do |_, args|
  stdout = IO::Memory.new
  stderr = IO::Memory.new

  result = KubectlClient::Get.delete_all_clusterpolicies_and_policyreports_allnamespaces()

  if !result[:status].success?
    stdout_failure "Kyverno policies could not be uninstalled. Please uninstall manually"
  else
    stdout_success "Kyverno policies were uninstalled successfully"
  end
end
