require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "../src/tasks/utils/airgap.cr"
require "file_utils"
require "sam"

describe "AirGap" do

  before_each do
    `./cnf-testsuite cleanup`
    $?.success?.should be_true
    unless Dir.exists?("./tmp")
      LOGGING.info `mkdir ./tmp`
    end
  end

  it "'setup' task should accept a tarball and put files in the /tmp directory", tags: ["airgap-setup"] do

    #./cnf-testsuite setup offline=./airgapped.tar.gz
    LOGGING.info `./cnf-testsuite airgapped output-file=./tmp/airgapped.tar.gz`
    LOGGING.info `./cnf-testsuite setup offline=./tmp/airgapped.tar.gz`
    file_list = `tar -tvf ./tmp/airgapped.tar.gz`
    LOGGING.info "file_list: #{file_list}"
    (file_list).match(/kubectl.tar/).should_not be_nil
    (file_list).match(/chaos-mesh.tar/).should_not be_nil
    (file_list).match(/chaos-daemon.tar/).should_not be_nil
    (file_list).match(/chaos-dashboard.tar/).should_not be_nil
    (file_list).match(/chaos-kernel.tar/).should_not be_nil
    (file_list).match(/prometheus.tar/).should_not be_nil
    (file_list).match(/download\/sonobuoy.tar.gz/).should_not be_nil
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
  ensure
    `rm ./tmp/airgapped.tar.gz`
    `rm ./tmp/cnf-testsuite.yml`
    `rm /tmp/airgapped.tar.gz`
    `rm /tmp/cnf-testsuite.yml`
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup a cnf helm chart in airgapped mode", tags: ["airgap-cleanup"]  do
    begin
      AirGap.tmp_cleanup
      `rm ./tmp/airgapped.tar.gz` if File.exists?("./tmp/airgapped.tar.gz")
      response_s = `./cnf-testsuite cnf_setup cnf-config=example-cnfs/coredns/cnf-testsuite.yml airgapped=./tmp/airgapped.tar.gz`
      LOGGING.info response_s
      response_s = `./cnf-testsuite cnf_setup cnf-config=example-cnfs/coredns/cnf-testsuite.yml input-file=./tmp/airgapped.tar.gz`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Successfully setup coredns/ =~ response_s).should_not be_nil
    ensure
      `rm ./tmp/airgapped.tar.gz/`
      AirGap.tmp_cleanup

      response_s = `./cnf-testsuite cnf_cleanup cnf-config=example-cnfs/coredns/cnf-testsuite.yml`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Successfully cleaned up/ =~ response_s).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup a cnf helm directory in airgapped mode", tags: ["airgap"]  do
    begin
      AirGap.tmp_cleanup
      `rm ./tmp/airgapped.tar.gz` if File.exists?("./tmp/airgapped.tar.gz")
      response_s = `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_coredns/cnf-testsuite.yml airgapped=./tmp/airgapped.tar.gz`
      LOGGING.info response_s
      response_s = `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_coredns/cnf-testsuite.yml input-file=./tmp/airgapped.tar.gz`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Successfully setup coredns/ =~ response_s).should_not be_nil
    ensure
      `rm ./tmp/airgapped.tar.gz` if File.exists?("./tmp/airgapped.tar.gz")
      AirGap.tmp_cleanup

      response_s = `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample_coredns/cnf-testsuite.yml`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Successfully cleaned up/ =~ response_s).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup a cnf manifest directory in airgapped mode", tags: ["airgap"]  do
    begin
      AirGap.tmp_cleanup
      `rm ./tmp/airgapped.tar.gz` if File.exists?("./tmp/airgapped.tar.gz")
      response_s = `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/k8s-non-helm/cnf-testsuite.yml airgapped=./tmp/airgapped.tar.gz`
      LOGGING.info response_s
      response_s = `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/k8s-non-helm/cnf-testsuite.yml input-file=./tmp/airgapped.tar.gz`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Successfully setup nginx-webapp/ =~ response_s).should_not be_nil
    ensure
      `rm ./tmp/airgapped.tar.gz` if File.exists?("./tmp/airgapped.tar.gz")
      AirGap.tmp_cleanup

      response_s = `LOG_LEVEL=debug ./cnf-testsuite cnf_cleanup installed-from-manifest=true cnf-config=sample-cnfs/k8s-non-helm/cnf-testsuite.yml`
      LOGGING.info response_s
      (/Successfully cleaned up/ =~ response_s).should_not be_nil
      $?.success?.should be_true
    end
  end

  it "'airgapped' task should accept a tarball", tags: ["airgap"] do

    LOGGING.info `./cnf-testsuite airgapped output-file=./tmp/airgapped.tar.gz`
    (File.exists?("./tmp/airgapped.tar.gz")).should be_true
  ensure
    `rm ./tmp/airgapped.tar.gz`
  end
end
