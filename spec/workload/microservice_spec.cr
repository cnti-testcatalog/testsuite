require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "kubectl_client"
require "../../src/tasks/utils/system_information/helm.cr"
require "../../src/tasks/dockerd_setup.cr"
require "file_utils"
require "sam"

describe "Microservice" do

  it "'single_process_type' should pass if the containers in the cnf have only one process type", tags: ["process_check"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-path=sample-cnfs/sample_coredns`
      response_s = `./cnf-testsuite single_process_type verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Only one process type used/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_coredns`
      $?.success?.should be_true
    end
  end

  it "'single_process_type' should fail if the containers in the cnf have more than one process type", tags: ["process_check"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-path=sample-cnfs/k8s-multiple-processes`
      response_s = `./cnf-testsuite single_process_type verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: More than one process type used/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/k8s-multiple-processes`
      $?.success?.should be_true
    end
  end

  it "'single_process_type' should fail if the containers in the cnf have more than one process type and in a pod", tags: ["process_check"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-path=sample-cnfs/sample-multiple-processes`
      response_s = `./cnf-testsuite single_process_type verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: More than one process type used/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample-multiple-processes`
      $?.success?.should be_true
    end
  end

  it "'reasonable_startup_time' should pass if the cnf has a reasonable startup time(helm_directory)", tags: ["reasonable_startup_time"]  do
      LOGGING.info `kubectl apply -f #{TOOLS_DIR}/cri-tools/manifest.yml`
      $?.success?.should be_true
      pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
      pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")
      LOGGING.info "CRI Pod: #{pods[0]}"
      KubectlClient::Get.resource_wait_for_install("DaemonSet", "cri-tools")
      LOGGING.info "CPU Logs"
      LOGGING.info "#{KubectlClient.exec("#{pods[0].dig?("metadata", "name")} -ti -- sysbench --test=cpu --num-threads=4 --cpu-max-prime=9999 run")}"
      LOGGING.info "Memory logs" 
      LOGGING.info "#{KubectlClient.exec("#{pods[0].dig?("metadata", "name")} -ti -- sysbench --test=memory --memory-block-size=1M --memory-total-size=100G --num-threads=1 run")}"
      LOGGING.info "Disk logs"
      LOGGING.info "#{KubectlClient.exec("#{pods[0].dig?("metadata", "name")} -ti -- /bin/bash -c 'sysbench fileio prepare && sysbench fileio --file-test-mode=rndrw run'")}"
      `./cnf-testsuite cnf_setup cnf-path=sample-cnfs/sample_coredns`
    begin
      response_s = `./cnf-testsuite reasonable_startup_time verbose`
      LOGGING.info response_s
      
      (/PASSED: CNF had a reasonable startup time/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_coredns`
      $?.success?.should be_true
      LOGGING.info `kubectl delete -f #{TOOLS_DIR}/cri-tools/manifest.yml`
    end
  end

  it "'reasonable_startup_time' should fail if the cnf doesn't has a reasonable startup time(helm_directory)", tags: ["reasonable_startup_time"] do
    LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_envoy_slow_startup/cnf-testsuite.yml force=true`
    begin
      response_s = `./cnf-testsuite reasonable_startup_time verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      LOGGING.info `kubectl apply -f #{TOOLS_DIR}/cri-tools/manifest.yml`
      $?.success?.should be_true
      pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
      pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")
      LOGGING.info "CRI Pod: #{pods[0]}"
      KubectlClient::Get.resource_wait_for_install("DaemonSet", "cri-tools")
      LOGGING.info "#{KubectlClient.exec("#{pods[0].dig?("metadata", "name")} -ti -- sysbench --test=cpu --num-threads=4 --cpu-max-prime=9999 run")}"
      (/FAILED: CNF had a startup time of/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample_envoy_slow_startup/cnf-testsuite.yml force=true`
      $?.success?.should be_true
      LOGGING.info `kubectl delete -f #{TOOLS_DIR}/cri-tools/manifest.yml`
    end
  end

  it "'reasonable_image_size' should pass if image is smaller than 5gb, when using a protected image", tags: ["reasonable_image_size_test"]  do
    if ENV["PROTECTED_DOCKERHUB_USERNAME"]? && ENV["PROTECTED_DOCKERHUB_PASSWORD"]? && ENV["PROTECTED_DOCKERHUB_EMAIL"]? && ENV["PROTECTED_IMAGE_REPO"]
         cnf="./sample-cnfs/sample_coredns_protected"
       else
         cnf="./sample-cnfs/sample-coredns-cnf"
    end
    LOGGING.info `./cnf-testsuite cnf_setup cnf-path=#{cnf}`
    response_s = `./cnf-testsuite reasonable_image_size verbose`
    LOGGING.info response_s
    $?.success?.should be_true
    (/Image size is good/ =~ response_s).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-path=#{cnf}`
  end

  it "'reasonable_image_size' should fail if image is larger than 5gb", tags: ["reasonable_image_size"] do
    `./cnf-testsuite cnf_setup cnf-path=./sample-cnfs/sample_envoy_slow_startup wait_count=0`
    response_s = `./cnf-testsuite reasonable_image_size verbose`
    LOGGING.info response_s
    $?.success?.should be_true
    (/Image size too large/ =~ response_s).should_not be_nil
  ensure
    `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_envoy_slow_startup force=true`
  end

  it "'reasonable_image_size' should skip if dockerd does not install", tags: ["reasonable_image_size"] do
    cnf="./sample-cnfs/sample-coredns-cnf"
    LOGGING.info `./cnf-testsuite cnf_setup cnf-path=#{cnf}`
    LOGGING.info `./cnf-testsuite uninstall_dockerd`
    dockerd_tempname_helper

    response_s = `./cnf-testsuite reasonable_image_size verbose`
    LOGGING.info response_s
    $?.success?.should be_true
    (/SKIPPED: Skipping reasonable_image_size: Dockerd tool failed to install/ =~ response_s).should_not be_nil
  ensure
    LOGGING.info "reasonable_image_size skipped ensure"
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-path=#{cnf}`
    dockerd_name_helper
  end
end
