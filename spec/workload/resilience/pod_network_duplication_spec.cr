require "../../spec_helper"
require "colorize"
require "../../../src/tasks/utils/utils.cr"
require "helm"
require "file_utils"
require "sam"

describe "Resilience Pod Network duplication Chaos" do
  before_all do
    result = ShellCmd.run_testsuite("setup")
    result = ShellCmd.run_testsuite("configuration_file_setup")
    result[:status].success?.should be_true
  end

  it "'pod_network_duplication' A 'Good' CNF should not crash when network duplication occurs", tags: ["pod_network_duplication"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("pod_network_duplication verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(pod_network_duplication chaos test passed)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("uninstall_litmus")
      result[:status].success?.should be_true
    end
  end
end
