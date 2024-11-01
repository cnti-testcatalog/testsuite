require "../../spec_helper"
require "colorize"
require "../../../src/tasks/utils/utils.cr"
require "helm"
require "file_utils"
require "sam"

describe "Resilience Pod Network Latency Chaos" do
  before_all do
    result = ShellCmd.run_testsuite("setup")
    result = ShellCmd.run_testsuite("configuration_file_setup")
    result[:status].success?.should be_true
  end

  it "'pod_network_latency' A 'Good' CNF should not crash when network latency occurs", tags: ["pod_network_latency"]  do
    begin
      ShellCmd.new_cnf_setup("cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
      result = ShellCmd.run_testsuite("pod_network_latency verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(pod_network_latency chaos test passed)/ =~ result[:output]).should_not be_nil
    ensure
      ShellCmd.new_cnf_cleanup()
      result = ShellCmd.run_testsuite("uninstall_litmus")
      result[:status].success?.should be_true
    end
  end
end
