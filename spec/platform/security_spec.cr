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

  it "'cluster_admin' should fail on a cnf that uses a cluster admin binding", tags: ["security"] do
    begin
      # LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
      # $?.success?.should be_true
      response_s = `./cnf-testsuite platform:cluster_admin`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Users with cluster admin role found/ =~ response_s).should_not be_nil
    # ensure
    #   `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
    end
  end
end

