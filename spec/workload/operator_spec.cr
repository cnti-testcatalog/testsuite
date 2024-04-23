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

  it "'operator_test' test if operator is being used", tags: ["operator_test"]  do
    current_dir = FileUtils.pwd
    install_dir = "#{tools_path}/olm"
    if Dir.exists?("#{install_dir}/olm/.git")
      Log.info { "OLM already installed. Skipping git clone for OLM." }
    else
      GitClient.clone("https://github.com/operator-framework/operator-lifecycle-manager.git #{install_dir}")
      `cd #{install_dir} && git fetch -a && git checkout tags/v0.22.0 && cd -`
    end

    Helm.install("operator --set olm.image.ref=quay.io/operator-framework/olm:v0.22.0 --set catalog.image.ref=quay.io/operator-framework/olm:v0.22.0 --set package.image.ref=quay.io/operator-framework/olm:v0.22.0 #{install_dir}/deploy/chart/")

    begin
      LOGGING.info `./cnf-testsuite -l info cnf_setup cnf-path=./sample-cnfs/sample_operator`
      $?.success?.should be_true
      resp = `./cnf-testsuite -l info operator_installed`
      Log.info { "#{resp}" }
      (/(PASSED).*(Operator is installed)/ =~ resp).should_not be_nil
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

      second_count = 0
      wait_count = 20
      delete=false
      until delete || second_count > wait_count.to_i
        File.write("operator.json", "#{KubectlClient::Get.namespaces("operators").to_json}")
        json = File.open("operator.json") do |file|
          JSON.parse(file)
        end
        json.as_h.delete("spec")
        File.write("operator.json", "#{json.to_json}")
        Log.info { "Uninstall Namespace Finalizer" }
        if KubectlClient::Replace.command("--raw '/api/v1/namespaces/operators/finalize' -f ./operator.json")[:status].success?
          delete=true
        end
        sleep 3
      end

      second_count = 0
      wait_count = 20
      delete=false
      until delete || second_count > wait_count.to_i
        File.write("manager.json", "#{KubectlClient::Get.namespaces("operator-lifecycle-manager").to_json}")
        json = File.open("manager.json") do |file|
          JSON.parse(file)
        end
        json.as_h.delete("spec")
        File.write("manager.json", "#{json.to_json}")
        Log.info { "Uninstall Namespace Finalizer" }
        if KubectlClient::Replace.command("--raw '/api/v1/namespaces/operator-lifecycle-manager/finalize' -f ./manager.json")[:status].success?
          delete=true
        end
        sleep 3
      end
     end
  end
  
  it "'operator_test' operator should not be found", tags: ["operator_test"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-path=sample-cnfs/sample_coredns`
      $?.success?.should be_true
      resp = `./cnf-testsuite -l info operator_installed`
      Log.info { "#{resp}" }
      (/(N\/A).*(No Operators Found)/ =~ resp).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_coredns`
      $?.success?.should be_true
    end
  end
end
