require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/kind_setup.cr"
require "file_utils"
require "sam"

describe "Compatibility" do
  
  before_all do
    `./cnf-testsuite setup`
    $?.success?.should be_true
  end

  it "'cni_compatible' should pass if the cnf works with calico and flannel", tags: ["compatibility"]  do
    begin
      `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      $?.success?.should be_true
      retry_limit = 5 
      retries = 1
      response_s = "" 
      until (/PASSED/ =~ response_s) || retries > retry_limit
        Log.info {"cni_compatible spec retry: #{retries}"}
        sleep 1.0
        response_s = `./cnf-testsuite cni_compatible verbose`
        retries = retries + 1
      end
      Log.info {"Status:  #{response_s}"}
      (/PASSED: CNF compatible with both Calico and Cilium/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      $?.success?.should be_true
    end
  end

  it "'increase_decrease_capacity' should pass ", tags: ["increase_decrease_capacity"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite increase_decrease_capacity verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Replicas increased to/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
    end
  end
end
