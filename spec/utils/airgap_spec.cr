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

  it "'image_pull_policy' should change all imagepull policy references to never", tags: ["kubectl-runtime"] do

    AirGapUtils.image_pull_policy("./spec/fixtures/litmus-operator-v1.13.2.yaml", "./tmp/imagetest.yml")
    (File.exists?("./tmp/imagetest.yml")).should be_true
    resp = File.read("./tmp/imagetest.yml") 
    (resp).match(/imagePullPolicy: Always/).should be_nil
    (resp).match(/imagePullPolicy: Never/).should_not be_nil
  ensure
    # `rm ./tmp/imagetest.yml`
  end
   
  it "'generate' should generate a tarball", tags: ["kubectl-runtime"] do

    AirGap.generate("./tmp/airgapped.tar.gz")
    (File.exists?("./tmp/airgapped.tar.gz")).should be_true
    file_list = `tar -tvf ./tmp/airgapped.tar.gz`
    LOGGING.info "file_list: #{file_list}"
    (file_list).match(/kubectl.tar/).should_not be_nil
    (file_list).match(/chaos-mesh.tar/).should_not be_nil
    (file_list).match(/chaos-daemon.tar/).should_not be_nil
    (file_list).match(/chaos-dashboard.tar/).should_not be_nil
    (file_list).match(/chaos-kernel.tar/).should_not be_nil
    (file_list).match(/prometheus.tar/).should_not be_nil
    (file_list).match(/rbac.yaml/).should_not be_nil
    (file_list).match(/disk-fill-rbac.yaml/).should_not be_nil
    (file_list).match(/litmus-operator/).should_not be_nil
    (file_list).match(/download\/sonobuoy.tar.gz/).should_not be_nil
  ensure
    `rm ./tmp/airgapped.tar.gz`
  end

  it "'#AirGap.publish_tarball' should execute publish a tarball to a bootstrapped cluster", tags: ["kubectl-runtime"]  do
    AirGap.download_cri_tools
    AirGap.bootstrap_cluster()
    tarball_name = "./spec/fixtures/testimage.tar.gz"
    resp = AirGap.publish_tarball(tarball_name)
    resp[0][:output].to_s.match(/unpacking docker.io\/testimage\/testimage:test/).should_not be_nil
  end

  it "'#AirGap.check_tar' should determine if a pod has the tar binary on it", tags: ["kubectl-runtime"]  do
    pods = KubectlClient::Get.pods
    resp = AirGap.check_tar(pods.dig?("metadata", "name"))
    resp.should be_false
  end
  
  it "'#AirGap.check_tar' should determine if the host has the tar binary on it", tags: ["kubectl-runtime"]  do
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")
    resp = AirGap.check_tar(pods[0].dig?("metadata", "name"), pod=false)
    LOGGING.debug "Path to tar on the host filesystem: #{resp}"
    resp.should_not be_nil 
  end

  it "'#AirGap.check_sh' should determine if a pod has a shell on it", tags: ["kubectl-runtime"]  do
    pods = KubectlClient::Get.pods
    resp = AirGap.check_sh(pods.dig?("metadata", "name"))
    resp.should be_false
  end

  it "'#AirGap.pods_with_tar' should determine if there are any pods with a shell and tar on them", tags: ["kubectl-runtime"]  do
    #TODO Should install cri-tools or container with tar before running spec.
    resp = AirGap.pods_with_tar()
    if resp[0].dig?("metadata", "name")
      LOGGING.debug "Pods With Tar Found #{resp[0].dig?("metadata", "name")}"
    end
    (resp[0].dig?("kind")).should eq "Pod"
  end

  it "'#AirGap.pods_with_sh' should determine if there are any pods with a shell on them", tags: ["kubectl-runtime"]  do
    resp = AirGap.pods_with_sh()
    (resp[0].dig?("kind")).should eq "Pod"
  end

  it "'#AirGap.download_cri_tools' should download the cri tools", tags: ["kubectl-runtime"]  do
    resp = AirGap.download_cri_tools()
    (File.exists?("/tmp/images/crictl-#{AirGap::CRI_VERSION}-linux-amd64.tar.gz")).should be_true
    (File.exists?("/tmp/images/containerd-#{AirGap::CTR_VERSION}-linux-amd64.tar.gz")).should be_true
  end

  it "'#AirGap.untar_cri_tools' should untar the cri tools", tags: ["kubectl-runtime"]  do
    AirGap.download_cri_tools
    resp = AirGap.untar_cri_tools()
    (File.exists?("/tmp/crictl")).should be_true
    (File.exists?("/tmp/bin/ctr")).should be_true
  end

  it "'#AirGap.pod_images' should retrieve all of the images for the pods with shells", tags: ["kubectl-runtime"]  do
    pods = AirGap.pods_with_tar()
    resp = AirGap.pod_images(pods)
    # (resp[0]).should eq "conformance/cri-tools:latest"
    (resp[0]).should_not be_nil
  end

  it "'#AirGap.create_pod_by_image' should install the cri pod in the cluster", tags: ["kubectl-runtime"]  do
      pods = AirGap.pods_with_tar()
      image = AirGap.pod_images(pods)
      resp = AirGap.create_pod_by_image(image)
      (resp).should be_true
  end

  it "'#AirGap.bootstrap_cluster' should install the cri tools in the cluster that has an image with tar avaliable on the node.", tags: ["kubectl-runtime"]  do
    pods = AirGap.pods_with_tar()
    if pods.empty?
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./example-cnfs/envoy/cnf-testsuite.yml deploy_with_chart=false`
      $?.success?.should be_true
    end
    AirGap.bootstrap_cluster()
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")
    # Get the generated name of the cri-tools per node
    pods.map do |pod| 
      pod_name = pod.dig?("metadata", "name")
      containers = pod.dig("spec","containers").as_a
      image = containers[0]? && containers[0].dig("image")
      LOGGING.info "CRI Pod Image: #{image}"
      sh = KubectlClient.exec("-ti #{pod_name} -- cat /usr/local/bin/crictl > /dev/null")  
      sh[:status].success?
      sh = KubectlClient.exec("-ti #{pod_name} -- cat /usr/local/bin/ctr > /dev/null")  
      sh[:status].success?
    end
  ensure
    KubectlClient::Delete.command("daemonset cri-tools")
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./example-cnfs/envoy/cnf-testsuite.yml deploy_with_chart=false`
  end


  it "'#AirGap.bootstrap_cluster' should install the cri tools in the cluster that does not have tar in the images", tags: ["kubectl-utils"]  do

    # TODO Delete all cri-tools images
    KubectlClient::Delete.command("daemonset cri-tools")
    pods = AirGap.pods_with_tar()
    # Skip the test if tar and sh is available outside of the cri tools 
    if !pods.empty?
      KubectlClient::Get
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
  ensure
    KubectlClient::Delete.command("daemonset cri-tools")
  end

  it "'#AirGap.cache_images' should install the cri tools in the cluster", tags: ["kubectl-utils"]  do
    AirGap.generate("./airgapped.tar.gz")
    resp = AirGap.cache_images
    LOGGING.info "#{resp.find{|x| puts x[0][:output].to_s}}"
    resp.find{|x|x[0][:output].to_s.match(/unpacking docker.io\/bitnami\/kubectl:latest/)}.should_not be_nil
    resp.find{|x|x[0][:output].to_s.match(/unpacking docker.io\/pingcap\/chaos-mesh:v1.2.1/)}.should_not be_nil

  ensure
    `rm /tmp/images/kubectl.tar`
    `rm /tmp/images/chaos-mesh.tar`
    `rm /tmp/images/chaos-daemon.tar`
    `rm /tmp/images/chaos-dashboard.tar`
    `rm /tmp/images/chaos-kernel.tar`
    `rm /tmp/images/sonobuoy.tar`
    `rm /tmp/images/sonobuoy-logs.tar`
    `rm /tmp/images/litmus-operator.tar`
    `rm /tmp/images/litmus-runner.tar`
    `rm /tmp/images/prometheus.tar`
  end

end



