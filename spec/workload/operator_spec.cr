require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/mysql.cr"
require "kubectl_client"
require "helm"
require "file_utils"
require "sam"
require "json"

describe "Operator" do
  before_all do
    current_dir = FileUtils.pwd
    install_dir = "#{current_dir}/#{TOOLS_DIR}/olm"
    if Dir.exists?("#{install_dir}/olm/.git")
      Log.info { "OLM already installed. Skipping git clone for OLM." }
    else
      GitClient.clone("https://github.com/operator-framework/operator-lifecycle-manager.git #{install_dir}")
      `cd #{install_dir} && git fetch -a && git checkout tags/v0.22.0 && cd -`
    end

    Helm.install("operator --set olm.image.ref=quay.io/operator-framework/olm:v0.22.0 --set catalog.image.ref=quay.io/operator-framework/olm:v0.22.0 --set package.image.ref=quay.io/operator-framework/olm:v0.22.0 #{install_dir}/deploy/chart/")
  end

  it "'operator_test' test if operator is being used", tags: ["operator_test"]  do
    begin
      LOGGING.info `./cnf-testsuite -l info cnf_setup cnf-path=./sample-cnfs/sample_operator`
      $?.success?.should be_true
      LOGGING.info `./cnf-testsuite -l info operator_installed`
    ensure
      LOGGING.info `./cnf-testsuite -l info cnf_cleanup cnf-path=./sample-cnfs/sample_operator`
      $?.success?.should be_true
      pods = KubectlClient::Get.pods_by_resource(KubectlClient::Get.deployment("catalog-operator", "operator-lifecycle-manager"), "operator-lifecycle-manager") + KubectlClient::Get.pods_by_resource(KubectlClient::Get.deployment("olm-operator", "operator-lifecycle-manager"), "operator-lifecycle-manager") + KubectlClient::Get.pods_by_resource(KubectlClient::Get.deployment("packageserver", "operator-lifecycle-manager"), "operator-lifecycle-manager")

      Helm.uninstall("operator")
      KubectlClient::Delete.command("csv prometheusoperator.0.47.0")

      pods.map do |pod| 
        pod_name = pod.dig("metadata", "name")
        pod_namespace = pod.dig("metadata", "namespace")
        Log.info { "Wait for Uninstall on Pod Name: #{pod_name}, Namespace: #{pod_namespace}" }
        KubectlClient::Get.resource_wait_for_uninstall("Pod", "#{pod_name}", 180, "operator-lifecycle-manager")
      end

      File.write("operator.json", "#{KubectlClient::Get.namespaces("operators").to_json}")
      json = File.open("operator.json") do |file|
        JSON.parse(file)
      end
      json.as_h.delete("spec")
      File.write("operator.json", "#{json.to_json}")
      KubectlClient::Replace.command("--raw '/api/v1/namespaces/operators/finalize' -f ./operator.json")

      File.write("manager.json", "#{KubectlClient::Get.namespaces("operator-lifecycle-manager").to_json}")
      json = File.open("manager.json") do |file|
        JSON.parse(file)
      end
      json.as_h.delete("spec")
      File.write("manager.json", "#{json.to_json}")
      KubectlClient::Replace.command("--raw '/api/v1/namespaces/operator-lifecycle-manager/finalize' -f ./manager.json")
     end
  end
end
