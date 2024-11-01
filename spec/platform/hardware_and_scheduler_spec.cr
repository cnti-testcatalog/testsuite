require "./../spec_helper"
require "colorize"
require "./../../src/tasks/utils/utils.cr"

describe "Platform" do
  before_all do
    result = ShellCmd.environment_cleanup()
    result = ShellCmd.run_testsuite("setup")
    result[:status].success?.should be_true
  end

  it "'oci_compliant' should pass if all runtimes are oci_compliant", tags: ["platform:oci_compliant"] do
      result = ShellCmd.run_testsuite("platform:oci_compliant")
      (/(PASSED).*(which are OCI compliant runtimes)/ =~ result[:output]).should_not be_nil
  end
end

