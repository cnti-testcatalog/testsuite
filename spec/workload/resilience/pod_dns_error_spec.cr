require "../../spec_helper"
require "colorize"
require "../../../src/tasks/utils/utils.cr"
require "helm"
require "file_utils"
require "sam"

describe "Resilience pod dns error Chaos" do
  before_all do
    result = ShellCmd.run_testsuite("setup")
    result = ShellCmd.run_testsuite("configuration_file_setup")
    result[:status].success?.should be_true
  end

  it "'pod_dns_error' A 'Good' CNF should not crash when pod dns error occurs", tags: ["pod_dns_error"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=example-cnfs/envoy/cnf-testsuite.yml")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("pod_dns_error verbose")
      result[:status].success?.should be_true
      ((/(SKIPPED).*(pod_dns_error docker runtime not found)/)  =~ result[:output] || 
       (/(PASSED).*(pod_dns_error chaos test passed)/ =~ result[:output])).should_not be_nil
    rescue ex
      # Raise back error to ensure test fails.
      # The ensure block will cleanup the CNF and the litmus installation.
      raise "Test failed with #{ex.message}"
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=example-cnfs/envoy/cnf-testsuite.yml")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("uninstall_litmus")
      result[:status].success?.should be_true
    end
  end
end
