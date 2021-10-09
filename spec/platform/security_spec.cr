require "./../spec_helper"
require "colorize"
require "./../../src/tasks/utils/utils.cr"

describe "Platform" do
  before_all do
    `./cnf-testsuite setup`
    $?.success?.should be_true
  end
  it "'control_plane_hardening' should pass if the control plane has been hardened", tags: ["platform:security"] do
    response_s = `./cnf-testsuite platform:control_plane_hardening`
    LOGGING.info response_s
    (/(PASSED: Control plane hardened)/ =~ response_s).should_not be_nil
  end
end

