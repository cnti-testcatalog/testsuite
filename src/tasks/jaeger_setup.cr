require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Install Jaeger"
task "install_jaeger" do |_, args|
  JaegerManager.install
end

desc "Uninstall Jaeger"
task "uninstall_jaeger" do |_, args|
  JaegerManager.uninstall
end

module JaegerManager
  def self.uninstall
    Log.for("verbose").info { "uninstall_jaeger" } 
    Helm.delete("jaeger")
  end

  def self.install
    Log.info {"Installing Jaeger daemonset "}
    Helm.helm_repo_add("jaegertracing","https://jaegertracing.github.io/helm-charts")
    Helm.install("--set hotrod.enabled=true jaeger jaegertracing/jaeger ")
    KubectlClient::Get.resource_wait_for_install("Deployment", "jaeger-collector")
    KubectlClient::Get.resource_wait_for_install("Deployment", "jaeger-hotrod")
    KubectlClient::Get.resource_wait_for_install("Deployment", "jaeger-query")
    KubectlClient::Get.resource_wait_for_install("Daemonset", "jaeger-agent")
  end

end

