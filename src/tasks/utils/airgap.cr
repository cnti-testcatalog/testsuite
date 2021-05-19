# coding: utf-8
require "totem"
require "colorize"
require "./tar.cr"
require "./kubectl_client.cr"

module AirGap
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



    # TODO OPTIONAL if registry
    # TODO if copy ..
    # TODO Add function to search all running pods for any that have both the tar & sh command available, or just sh as a secondary. 
    # TODO get all the pods for all namespaces
    # TODO determine if pod has a shell
    # TODO get the image id of the shell
    # TODO Make an embedded file for deploying the cri-tool 
    # TODO download cri tools
    # TODO install cri-tool
    # TODO Function to install needed cri & ctr tools using kubectl cp.
    # TODO make sure cri tools are installed (wait for them)

    #TODO Function to install a generic pod to the cluster using a passed image id.

    # TODO add tar binary to prereqs/documentation
    # TODO Function to mount the tar binary from the host file system & add to path. * Only needed if using sh only secondary.

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

