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

  it "'elastic_volume' should pass if the cnf uses an elastic volume", tags: ["elastic_volume"]  do
    begin
      LOGGING.info `./cnf-testsuite -l info cnf_setup cnf-config=./sample-cnfs/sample-elastic-volume/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite -l info elastic_volumes verbose`
      LOGGING.info "Status:  #{response_s}"
      (/PASSED: Elastic Volumes Used/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-elastic-volume/cnf-testsuite.yml`
      $?.success?.should be_true
    end
  end
end
