require "../../spec_helper"
require "colorize"
require "../../../src/tasks/utils/utils.cr"
require "../../../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "Resilience pod dns error Chaos" do
  before_all do
    `./cnf-testsuite setup`
    `./cnf-testsuite configuration_file_setup`
    $?.success?.should be_true
  end

  it "'pod_dns_error' A 'Good' CNF should not crash when pod dns error occurs", tags: ["pod_dns_error"]  do
    begin
     Log.info { `./cnf-testsuite cnf_setup cnf-config=example-cnfs/envoy/cnf-testsuite.yml`}
      $?.success?.should be_true
      response_s = `./cnf-testsuite pod_dns_error verbose`
      Log.info { response_s }
      $?.success?.should be_true
      ((/SKIPPED: pod_dns_error docker runtime not found/)  =~ response_s || 
       (/PASSED: pod_dns_error chaos test passed/ =~ response_s)).should_not be_nil
    ensure
      Log.info {`./cnf-testsuite cnf_cleanup cnf-config=example-cnfs/envoy/cnf-testsuite.yml`}
      $?.success?.should be_true
      Log.info {`./cnf-testsuite uninstall_litmus`}
      $?.success?.should be_true
    end
  end
end
