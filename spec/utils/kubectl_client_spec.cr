require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/kubectl_client.cr"
require "file_utils"
require "sam"

describe "KubectlClient" do
  # after_all do
  # end

  it "'Kubectl::Get.wait_for_install' should wait for a cnf to be installed", tags: ["kubectl-install"]  do
    LOGGING.debug `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-conformance.yml verbose wait_count=0`

    $?.success?.should be_true

    current_dir = FileUtils.pwd 
    LOGGING.info current_dir
    #helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    helm = CNFSingleton.helm
    LOGGING.info helm
    helm_install = `#{helm} install coredns stable/coredns`
    LOGGING.info helm_install
    KubectlClient::Get.wait_for_install("coredns-coredns")
    current_replicas = `kubectl get deployments coredns-coredns -o=jsonpath='{.status.readyReplicas}'`
    (current_replicas.to_i > 0).should be_true
  end

  it "'#KubectlClient.get_nodes' should return the information about a node in json", tags: ["kubectl-nodes"]  do
    json = KubectlClient::Get.nodes
    (json["items"].size).should be > 0
  end
  it "'#KubectlClient.container_runtime' should return the information about the container runtime", tags: ["kubectl-runtime"]  do
    resp = KubectlClient::Get.container_runtime
    (resp.match(KubectlClient::OCI_RUNTIME_REGEX)).should_not be_nil
  end
  it "'#KubectlClient.container_runtimes' should return all container runtimes", tags: ["kubectl-runtime"]  do
    resp = KubectlClient::Get.container_runtimes
    (resp[0].match(KubectlClient::OCI_RUNTIME_REGEX)).should_not be_nil
  end

  it "'#KubectlClient.schedulable_nodes' should return all schedulable worker nodes", tags: ["kubectl-nodes"]  do
    resp = KubectlClient::Get.schedulable_nodes
    (resp.size).should be > 0
    (resp[0]).should_not be_nil
    (resp[0]).should_not be_empty
  end

  it "'#KubectlClient.containers' should return all containers defined in a deployment", tags: ["kubectl-pods"]  do
    LOGGING.debug `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/k8s-sidecar-container-pattern/cnf-conformance.yml wait_count=0` 
    resp = KubectlClient::Get.deployment_containers("nginx-webapp")
    (resp.size).should be > 0
  ensure
    LOGGING.debug `./cnf-conformance cnf_cleanup cnf-config=./sample-cnfs/k8s-sidecar-container-pattern/cnf-conformance.yml deploy_with_chart=false` 
  end

  it "'#KubectlClient.pod_exists?' should true if a pod exists", tags: ["kubectl-pods"]  do
    LOGGING.debug `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample-generic-cnf/cnf-conformance.yml` 
    resp = KubectlClient::Get.pod_exists?("coredns")
    (resp).should be_true 
  ensure
    LOGGING.debug `./cnf-conformance cnf_cleanup cnf-config=./sample-cnfs/sample-generic-cnf/cnf-conformance.yml` 
  end
 
end

