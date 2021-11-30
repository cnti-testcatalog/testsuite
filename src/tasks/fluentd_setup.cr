require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Install Fluentd"
task "install_fluentd" do |_, args|
  FluentDManager.install
end

desc "Uninstall Fluentd"
task "uninstall_fluentd" do |_, args|
  FluentDManager.uninstall
end

module FluentDManager
  def self.uninstall
    Log.for("verbose").info { "uninstall_fluentd" } 
    Helm.delete("fluentd")
  end

  def self.install
    #todo use embedded file to install fluentd values over fluent helm
    #chart
    Log.info {"Installing FluentD daemonset "}
    File.write("fluentd-values.yml", FLUENTD_VALUES)
    Helm.helm_repo_add("fluent","https://fluent.github.io/helm-charts")
    #todo  #helm install --values ./override.yml fluentd ./fluentd
    Helm.install("--values ./fluentd-values.yml fluentd fluent/fluentd")
    KubectlClient::Get.resource_wait_for_install("Daemonset", "fluentd")
  end

end

