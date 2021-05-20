require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/airgap.cr"
require "../../src/tasks/utils/kubectl_client.cr"
require "file_utils"
require "sam"

describe "AirGap" do
    unless Dir.exists?("./tmp")
      LOGGING.info `mkdir ./tmp`
    end

  it "'generate' should generate a tarball", tags: ["airgap"] do

    AirGap.generate("./tmp/airgapped.tar.gz")
    (File.exists?("./tmp/airgapped.tar.gz")).should be_true
  ensure
    `rm ./tmp/airgapped.tar.gz`
  end

  it "'#AirGap.publish_tarball' should execute publish a tarball to a bootstrapped cluster", tags: ["kubectl-nodes"]  do
    bootstrap = `cd ./tools ; ./bootstrap-cri-tools.sh registry conformance/cri-tools:latest ; cd -`
    tarball_name = "./spec/fixtures/testimage.tar.gz"
    resp = AirGap.publish_tarball(tarball_name)
    resp[0][:output].to_s.match(/unpacking docker.io\/testimage\/testimage:test/).should_not be_nil
  end

  it "'#AirGap.check_tar' should determine if a pod has the tar binary on it", tags: ["kubectl-nodes"]  do
    pods = KubectlClient::Get.pods
    resp = AirGap.check_tar(pods.dig?("metadata", "name"))
    resp.should be_false
  end

  it "'#AirGap.check_sh' should determine if a pod has a shell on it", tags: ["kubectl-nodes"]  do
    pods = KubectlClient::Get.pods
    resp = AirGap.check_sh(pods.dig?("metadata", "name"))
    resp.should be_false
  end

  it "'#AirGap.pods_with_tar' should determine if there are any pods with a shell and tar on them", tags: ["kubectl-nodes"]  do
    resp = AirGap.pods_with_tar()
    (resp[0].dig?("kind")).should eq "Pod"
  end

  it "'#AirGap.pods_with_sh' should determine if there are any pods with a shell on them", tags: ["kubectl-nodes"]  do
    resp = AirGap.pods_with_sh()
    (resp[0].dig?("kind")).should eq "Pod"
  end

  it "'#AirGap.download_cri_tools' should download the cri tools", tags: ["kubectl-nodes"]  do
    resp = AirGap.download_cri_tools()
    (File.exists?("crictl-#{AirGap::CRI_VERSION}-linux-amd64.tar.gz")).should be_true
    (File.exists?("containerd-#{AirGap::CTR_VERSION}-linux-amd64.tar.gz")).should be_true
  end

  it "'#AirGap.untar_cri_tools' should untar the cri tools", tags: ["kubectl-nodes"]  do
    resp = AirGap.untar_cri_tools()
    (File.exists?("/tmp/crictl")).should be_true
    (File.exists?("/tmp/bin/ctr")).should be_true
  end

  it "'#AirGap.pod_images' should retrieve all of the images for the pods with shells", tags: ["kubectl-nodes"]  do
    pods = AirGap.pods_with_tar()
    resp = AirGap.pod_images(pods)
    # (resp[0]).should eq "conformance/cri-tools:latest"
    (resp[0]).should_not be_nil
  end

  it "'#AirGap.create_pod_by_image' should install the cri pod in the cluster", tags: ["kubectl-nodes"]  do
      pods = AirGap.pods_with_tar()
      image = AirGap.pod_images(pods)
      resp = AirGap.create_pod_by_image(image)
      (resp).should be_true
  end

  it "'#AirGap.bootstrap_cluster' should install the cri tools in the cluster", tags: ["kubectl-nodes"]  do
    AirGap.bootstrap_cluster()
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")
    # Get the generated name of the cri-tools per node
    pods.map do |pod| 
      pod_name = pod.dig?("metadata", "name")
      sh = KubectlClient.exec("-ti #{pod_name} -- cat /usr/local/bin/crictl > /dev/null")  
      sh[:status].success?
      sh = KubectlClient.exec("-ti #{pod_name} -- cat /usr/local/bin/ctr > /dev/null")  
      sh[:status].success?
    end
  end

  it "'#AirGap.install_test_suite_tools' should install the cri tools in the cluster", tags: ["kubectl-nodes"]  do
    resp = AirGap.install_test_suite_tools
    resp[0][:output].to_s.match(/unpacking docker.io\/testimage\/testimage:test/).should_not be_nil
  end

end



