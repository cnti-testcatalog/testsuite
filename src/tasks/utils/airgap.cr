# coding: utf-8
require "totem"
require "colorize"
require "./tar.cr"

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

end

