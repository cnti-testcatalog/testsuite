require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"
require "tar"
require "./utils/operator.cr"

desc "Install Operator Lifecycle Manager"
task "install_olm" do |_, args|
  install_status = Operator::OLM.install

  if install_status
    stdout_success "Operator Lifecycle Manager successfully installed"
  else
    stdout_failure "Operator Lifecycle Manager installation failed"
    exit 1
  end
end

desc "Uninstall and Cleanup Operator Lifecycle Manager"
task "cleanup_olm" do |_, args|
  uninstall_status = Operator::OLM.cleanup

  if uninstall_status
    stdout_success "Operator Lifecycle Manager was uninstalled successfully"
  else
    stdout_failure "Operator Lifecycle Manager could not be uninstalled."
    exit 1
  end
end

desc "Uninstall and Cleanup Operator Lifecycle Manager"
task "uninstall_olm", ["cleanup_olm"] do |_, args|
end

# clear simple-privileged-operator namespace
desc "Clear simple-privileged-operator namespace"
task "clear_namespace_privileged_operator" do |_, args|
  Operator::OLM.clear_namespaces(["operators", "operator-lifecycle-manager", "simple-privileged-operator", "olm"])
end