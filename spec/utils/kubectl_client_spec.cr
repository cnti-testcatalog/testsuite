require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/kubectl_client.cr"
require "file_utils"
require "sam"

describe "KubectlClient" do
  # after_all do
  # end
  it "'#KubectlClient.get_nodes' should return the information about a node in json"  do
    json = KubectlClient::Get.nodes
    (json["items"].size).should be > 0
  end
  it "'#KubectlClient.container_runtime' should return the information about a node in json"  do
    resp = KubectlClient::Get.container_runtime
    (resp.match(KubectlClient::OCI_RUNTIME_REGEX)).should_not be_nil
  end
  it "'#KubectlClient.container_runtimes' should return all container runtimes"  do
    resp = KubectlClient::Get.container_runtimes
    (resp[0].match(KubectlClient::OCI_RUNTIME_REGEX)).should_not be_nil
  end

  it "'#KubectlClient.schedulable_nodes' should return all schedulable worker nodes"  do
    resp = KubectlClient::Get.schedulable_nodes
    (resp.size).should be > 0
    (resp[0]).should_not be_nil
    (resp[0]).should_not be_empty
  end

  it "'#KubectlClient.schedulable_nodes' should return all schedulable worker nodes"  do
    LOGGING.debug `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/k8s-sidecar-container-pattern/cnf-conformance.yml deploy_with_chart=false` 
    resp = KubectlClient::Get.deployment_containers("nginx-webapp")
    (resp.size).should be > 0
  ensure
    LOGGING.debug `./cnf-conformance cnf_cleanup cnf-config=./sample-cnfs/k8s-sidecar-container-pattern/cnf-conformance.yml deploy_with_chart=false` 
  end

  it "'#KubectlClient.pod_exists?' should true if a pod exists"  do
    LOGGING.debug `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample-generic-cnf/cnf-conformance.yml` 
    resp = KubectlClient::Get.pod_exists?("coredns")
    (resp).should be_true 
  ensure
    LOGGING.debug `./cnf-conformance cnf_cleanup cnf-config=./sample-cnfs/sample-generic-cnf/cnf-conformance.yml` 
  end
 
end

