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
    Log.info { response_s }
    (/(PASSED: Insecure port of Kubernetes API server is not enabled)/ =~ response_s).should_not be_nil
  end

  it "'cluster_admin' should fail on a cnf that uses a cluster admin binding", tags: ["platform:security"] do
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

  it "'helm_tiller' should fail if Helm Tiller is running in the cluster", tags: ["platform:security"] do
    ShellCmd.run("kubectl run tiller --image=rancher/tiller:v2.11.0", "create_tiller")
    KubectlClient::Get.resource_wait_for_install("pod", "tiller")
    response_s = `./cnf-testsuite platform:helm_tiller`
    $?.success?.should be_true
    (/FAILED: Containers with the Helm Tiller image are running/ =~ response_s).should_not be_nil
  ensure
    KubectlClient::Delete.command("pod/tiller")
    KubectlClient::Get.resource_wait_for_uninstall("pod", "tiller")
  end

  it "'helm_tiller' should fail if Helm Tiller is running in the cluster", tags: ["platform:security"] do
    # By default we have nothing to setup for this task to pass since Helm v3 does not use Tiller.
    response_s = `./cnf-testsuite platform:helm_tiller`
    $?.success?.should be_true
    (/PASSED: No Helm Tiller containers are running/ =~ response_s).should_not be_nil
  end
end
