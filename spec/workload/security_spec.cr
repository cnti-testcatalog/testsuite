require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"

describe "Security" do

  it "'non_root_user' should pass with a non-root cnf", tags: ["security"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_nonroot/cnf-testsuite.yml`
      response_s = `./cnf-testsuite non_root_user verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Root user not found/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample_nonroot/cnf-testsuite.yml`
      LOGGING.debug `./cnf-testsuite uninstall_falco`
      KubectlClient::Get.resource_wait_for_uninstall("DaemonSet", "falco")
    end
  end

  it "'non_root_user' should fail with a root cnf", tags: ["security"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/k8s-non-helm/cnf-testsuite.yml`
      response_s = `./cnf-testsuite non_root_user verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Root user found/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/k8s-non-helm/cnf-testsuite.yml`
      LOGGING.debug `./cnf-testsuite uninstall_falco`
      KubectlClient::Get.resource_wait_for_uninstall("DaemonSet", "falco")
    end
  end

  it "'privileged' should pass with a non-privileged cnf", tags: ["security"]  do
    begin
      LOGGING.debug `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-statefulset-cnf/cnf-testsuite.yml`
      response_s = `./cnf-testsuite privileged verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Found.*privileged containers.*coredns/ =~ response_s).should be_nil
    ensure
      LOGGING.debug `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-statefulset-cnf/cnf-testsuite.yml`
    end
  end
  it "'privileged' should fail on a non-whitelisted, privileged cnf", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_privileged_cnf/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite privileged verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Found.*privileged containers.*coredns/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite sample_privileged_cnf_non_whitelisted_cleanup`
    end
  end
  it "'privileged' should pass on a whitelisted, privileged cnf", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_whitelisted_privileged_cnf/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite privileged cnf-config=sample-cnfs/sample_whitelisted_privileged_cnf verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Found.*privileged containers.*coredns/ =~ response_s).should be_nil
    ensure
      `./cnf-testsuite sample_privileged_cnf_whitelisted_cleanup`
    end
  end
  it "'privilege_escalation' should fail on a cnf that has escalated privileges", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite privilege_escalation`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: No containers that allow privilege escalation were found/ =~ response_s).should be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
    end
  end

  it "'symlink_file_system' should pass on a cnf that does not allow a symlink attack", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite symlink_file_system`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: No containers allow a symlink attack/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
    end
  end

  it "'application_credentials' should fail on a cnf that allows applications credentials in configuration files", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite application_credentials`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Found applications credentials in configuration files/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
    end
  end

  it "'host_network' should pass on a cnf that does not have a host network attached to pod", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite host_network`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: No host network attached to pod/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
    end
  end
end
