# coding: utf-8
require "totem"
require "colorize"
require "./tar.cr"
require "./kubectl_client.cr"

module AirGap
  CRI_VERSION="v1.17.0"
  CTR_VERSION="1.5.0"
  #./cnf-testsuite airgapped -o ~/airgapped.tar.gz
  #./cnf-testsuite offline -o ~/airgapped.tar.gz
  #./cnf-testsuite offline -o ~/mydir/airgapped.tar.gz
  def self.generate(output_file : String = "./airgapped.tar.gz")
    #TODO find real images 
    #TODO tar real images 
    s1 = "./spec/fixtures/cnf-testsuite.yml"
    TarClient.tar(output_file, Path[s1].parent, s1.split("/")[-1])
  end

  #./cnf-testsuite setup --offline=./airgapped.tar.gz
  def self.extract(output_file : String = "./airgapped.tar.gz")
    #TODO untar real images to their appropriate directories
    #TODO  the second parameter will be determined based on
    # the image file that was tarred
    TarClient.untar(output_file, "./tmp")
  end

  def self.publish_tarball(tarball)
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    (pods).should_not be_nil
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")
    pods.map do |pod| 
      pod_name = pod.dig?("metadata", "name")
      KubectlClient.cp("#{tarball} #{pod_name}:/tmp/#{tarball.split("/")[-1]}")
    end
    pods.map do |pod| 
      pod_name = pod.dig?("metadata", "name")
      resp = KubectlClient.exec("-ti #{pod_name} -- ctr -n=k8s.io image import /tmp/#{tarball.split("/")[-1]}")
      LOGGING.debug "Resp: #{resp}"
      resp
    end
  end



  def self.bootstrap_cluster(method)
    resp = AirGap.pods_with_tar()
    resp = AirGap.download_cri_tools()
    resp = AirGap.untar_cri_tools()



    # TODO OPTIONAL if registry
    # TODO if copy ..
    # TODO Add function to search all running pods for any that have both the tar & sh command available, or just sh as a secondary. 
    # TODO get all the pods for all namespaces
    # TODO determine if pod has a shell
    # TODO get the image id of the shell
    # TODO Make an embedded file for deploying the cri-tool 
    # TODO download cri tools
    # TODO if tar exists
    # TODO if tar doest not exist, install tar
    # TODO install cri-tool
    # TODO Function to install needed cri & ctr tools using kubectl cp.
    # TODO make sure cri tools are installed (wait for them)

    #TODO Function to install a generic pod to the cluster using a passed image id.

    # TODO add tar binary to prereqs/documentation
    # TODO Function to mount the tar binary from the host file system & add to path. * Only needed if using sh only secondary.

  end

  #TODO put curl back in the prereqs
  def self.download_cri_tools
    `curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/#{CRI_VERSION}/crictl-#{CRI_VERSION}-linux-amd64.tar.gz --output crictl-#{CRI_VERSION}-linux-amd64.tar.gz`
    `curl -L https://github.com/containerd/containerd/releases/download/v#{CTR_VERSION}/containerd-#{CTR_VERSION}-linux-amd64.tar.gz --output containerd-#{CTR_VERSION}-linux-amd64.tar.gz`
  end

  def self.untar_cri_tools
    TarClient.untar("crictl-#{CRI_VERSION}-linux-amd64.tar.gz", "/tmp")
    TarClient.untar("containerd-#{CTR_VERSION}-linux-amd64.tar.gz", "/tmp")
  end

  def self.pod_images(pods)
    pods.map do |pod|
      containers = pod.dig("spec","containers").as_a
      #TODO make this work with multiple containers
      # Gets first image for every pod
      image = containers[0]? && containers[0].dig("image")
    end
  end

  def self.install_cri_tools(cri_tool_pods)
    cri_tool_pods.map do |pod|
      KubectlClient.cp("/tmp/crictl #{pod.dig?("metadata", "name")}:/usr/local/bin/crictl")
      KubectlClient.cp("/tmp/bin/ctr #{pod.dig?("metadata", "name")}:/usr/local/bin/ctr")
    end
  end

  def self.check_sh(pod_name)
    sh = KubectlClient.exec("-ti #{pod_name} -- cat /bin/sh > /dev/null")  
    sh[:status].success?
  end

  def self.check_tar(pod_name)
    bin_tar = KubectlClient.exec("-ti #{pod_name} -- cat /bin/tar > /dev/null")  
    usr_bin_tar =  KubectlClient.exec("-ti #{pod_name} -- cat /usr/bin/tar > /dev/null")
    usr_local_bin_tar = KubectlClient.exec("-ti #{pod_name} -- cat /usr/local/bin/tar > /dev/null")

    bin_tar[:status].success? || usr_bin_tar.[:status].success? || usr_local_bin_tar[:status].success?
  end

  def self.pods_with_tar() : KubectlClient::K8sManifestList
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list).select do |pod|
      pod_name = pod.dig?("metadata", "name")
      if check_sh(pod_name) && check_tar(pod_name)
        LOGGING.debug "Found tar and sh Pod: #{pod_name}"
        true
      else
        false
      end
    end
  end

  def self.pods_with_sh() : KubectlClient::K8sManifestList
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list).select do |pod|
      pod_name = pod.dig?("metadata", "name")
      if check_sh(pod_name) 
        LOGGING.debug "Found sh Pod: #{pod_name}"
        true
      else
        false
      end
    end
  end

end

