require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/kubectl_client.cr"
require "../../src/tasks/utils/system_information/helm.cr"
require "../../src/tasks/dockerd_setup.cr"
require "file_utils"
require "sam"

describe "Registry" do
  before_all do
    install_registry = `kubectl create -f #{TOOLS_DIR}/registry/manifest.yml`
    install_dockerd = `kubectl create -f #{TOOLS_DIR}/dockerd/manifest.yml`
  end

  it "'reasonable_image_size' should pass if using local registry and a port", tags: ["private_registry"]  do
    KubectlClient::Get.resource_wait_for_install("Pod", "registry")
    KubectlClient::Get.resource_wait_for_install("Pod", "dockerd")
    KubectlClient.exec("dockerd -ti -- docker pull coredns/coredns:1.6.7")
    KubectlClient.exec("dockerd -ti -- docker tag coredns/coredns:1.6.7 registry:5000/coredns:1.6.7")
    KubectlClient.exec("dockerd -ti -- docker push registry:5000/coredns:1.6.7")

    cnf="./sample-cnfs/sample_local_registry"

    LOGGING.info `./cnf-testsuite cnf_setup cnf-path=#{cnf} wait_count=0`
    response_s = `./cnf-testsuite reasonable_image_size verbose`
    LOGGING.info response_s
    $?.success?.should be_true
    (/Image size is good/ =~ response_s).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-path=#{cnf} wait_count=0`
  end

  it "'reasonable_image_size' should pass if using local registry, a port and an org", tags: ["private_registry"]  do
    KubectlClient::Get.resource_wait_for_install("Pod", "registry")
    KubectlClient::Get.resource_wait_for_install("Pod", "dockerd")
    KubectlClient.exec("dockerd -ti -- docker pull coredns/coredns:1.6.7")
    KubectlClient.exec("dockerd -ti -- docker tag coredns/coredns:1.6.7 registry:5000/coredns/coredns:1.6.7")
    KubectlClient.exec("dockerd -ti -- docker push registry:5000/coredns/coredns:1.6.7")

    cnf="./sample-cnfs/sample_local_registry_org_image"

    LOGGING.info `./cnf-testsuite cnf_setup cnf-path=#{cnf} wait_count=0`
    response_s = `./cnf-testsuite reasonable_image_size verbose`
    LOGGING.info response_s
    $?.success?.should be_true
    (/Image size is good/ =~ response_s).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-path=#{cnf} wait_count=0`
  end

  after_all do
    delete_registry = `kubectl delete -f #{TOOLS_DIR}/registry/manifest.yml`
    delete_dockerd = `kubectl delete -f #{TOOLS_DIR}/dockerd/manifest.yml`
  end
end
