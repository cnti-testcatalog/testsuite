require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/mysql.cr"
require "kubectl_client"
require "helm"
require "file_utils"
require "sam"

describe "Operator" do
  before_all do
    `git clone https://github.com/operator-framework/operator-lifecycle-manager.git`
    Helm.install("operator operator-lifecycle-manager/deploy/chart/")
  end

  it "'operator_test' test if operator is being used", tags: ["operator_test"]  do
    begin
      LOGGING.info `./cnf-testsuite -l info cnf_setup cnf-path=./sample-cnfs/sample_coredns`
      $?.success?.should be_true
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-elastic-volume/cnf-testsuite.yml`
      $?.success?.should be_true
      Helm.uninstall("operator")

      `kubectl get namespaces operators -o json > operator.json`
      `kubectl get namespaces operator-lifecycle-manager -o json > manager.json`
      json = File.open("operator.json") do |file|
        JSON.parse(file)
      end
      json.as_h.delete("spec")
      File.write("operatorupdate.json", "#{json.to_json}")

      json = File.open("manager.json") do |file|
        JSON.parse(file)
      end
      json.as_h.delete("spec")
      File.write("managerupdate.json", "#{json.to_json}")
      kubectl replace --raw "/api/v1/namespaces/operators/finalize" -f ./operators.json
      kubectl replace --raw "/api/v1/namespaces/operator-lifecycle-manager/finalize" -f ./operator-lifecycle-manager.json
    end
  end
end
