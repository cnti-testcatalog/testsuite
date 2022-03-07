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
    (/(PASSED: Control plane hardened)/ =~ response_s).should_not be_nil
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

  it "'exposed_dashboard' should fail when the Kubernetes dashboard is exposed", tags: ["platform:security"] do
    dashboard_install_url = "https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml"
    begin
      # Run the exposed_dashboard test to confirm no vulnerability before dashboard is installed
      response_s = `./cnf-testsuite platform:exposed_dashboard`
      (/PASSED: No exposed dashboard found in the cluster/ =~ response_s).should_not be_nil

      # Install the dashboard version 2.0.0.
      # According to the kubescape rule, anything less than v2.0.1 would fail.
      KubectlClient::Apply.file(dashboard_install_url)

      # Construct patch spec to expose Kubernetes Dashboard on a Node Port
      patch_spec = {
        spec: {
          type: "NodePort",
          ports: [
            {
              nodePort: 30500,
              port: 443,
              protocol: "TCP",
              targetPort: 8443
            }
          ]
        }
      }
      # Apply the patch to expose the dashboard on the NodePort
      result = KubectlClient::Patch.spec("service", "kubernetes-dashboard", patch_spec.to_json, "kubernetes-dashboard")

      # Run the test again to confirm vulnerability with an exposed dashboard
      response_s = `./cnf-testsuite platform:exposed_dashboard`
      Log.info { response_s }
      $?.success?.should be_true
      (/FAILED: Found exposed dashboard in the cluster/ =~ response_s).should_not be_nil
    ensure
      # Ensure to remove the Kubectl dashboard after the test
      KubectlClient::Delete.file(dashboard_install_url)
    end
  end

  it "'helm_tiller' should fail if Helm Tiller is running in the cluster" do
    ShellCmd.run("kubectl run tiller --image=rancher/tiller:v2.11.0", "create_tiller")
    response_s = `./cnf-testsuite platform:helm_tiller`
    $?.success?.should be_true
    (/FAILED: Containers with the Helm Tiller image are running/ =~ response_s).should_not be_nil
  ensure
    KubectlClient::Delete.command("pod/tiller")
    KubectlClient::Get.resource_wait_for_uninstall("pod", "tiller")
  end

  it "'helm_tiller' should fail if Helm Tiller is running in the cluster" do
    # By default we have nothing to setup for this task to pass since Helm v3 does not use Tiller.
    response_s = `./cnf-testsuite platform:helm_tiller`
    $?.success?.should be_true
    (/PASSED: No Helm Tiller containers are running/ =~ response_s).should_not be_nil
  end
end
