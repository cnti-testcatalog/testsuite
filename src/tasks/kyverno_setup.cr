require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"
require "tar"

desc "Install Kyverno"
task "install_kyverno" do |_, args|
  install_status = Kyverno.install

  if install_status
    stdout_success "Kyverno successfully installed"
  else
    stdout_success "Kyverno installation failed"
  end
end

desc "Uninstall Kyverno"
task "uninstall_kyverno" do |_, args|
  uninstall_status = Kyverno.uninstall

  if uninstall_status
    stdout_success "Kyverno was uninstalled successfully"
  else
    stdout_failure "Kyverno could not be uninstalled."
  end
end

desc "Delete all cluster policies and policy reports in all namespaces"
task "cleanup_policies" do |_, args|
  delete_cluster_policies = Kyverno::ClusterPolicy.delete_all
  delete_policy_reports = Kyverno::PolicyReport.delete_all

  if delete_cluster_policies && delete_policy_reports
    stdout_failure "Kyverno policies could not be uninstalled. Please uninstall manually"
  else
    stdout_success "Kyverno policies were uninstalled successfully"
  end
end
