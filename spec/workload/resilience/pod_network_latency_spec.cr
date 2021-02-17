require "../../spec_helper"
require "colorize"
require "../../../src/tasks/utils/utils.cr"
require "../../../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "Resilience Pod Network Latency Chaos" do
  before_all do
    `./cnf-conformance setup`
    `./cnf-conformance configuration_file_setup`
    $?.success?.should be_true
  end

  it "'pod_network_latency' A 'Good' CNF should not crash when network latency occurs", tags: ["pod_network_latency"]  do
    begin
      `./cnf-conformance cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-conformance.yml`
      $?.success?.should be_true
      response_s = `./cnf-conformance pod_network_latency verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: pod_network_latency chaos test passed/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-conformance.yml`
      $?.success?.should be_true
      `./cnf-conformance uninstall_litmus`
      $?.success?.should be_true
    end
  end
end
