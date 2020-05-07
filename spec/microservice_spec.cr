require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "Microservice" do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr samples_cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr configuration_file_setup`
    # `crystal src/cnf-conformance.cr setup`
    # $?.success?.should be_true
  end

  it "'reasonable_startup_time' should pass if the cnf has a reasonable startup time(helm_directory)", tags: "reasonable_startup_time" do
    `crystal src/cnf-conformance.cr sample_coredns_cleanup`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr reasonable_startup_time yml-file=sample-cnfs/sample_coredns/cnf-conformance.yml`
    $?.success?.should be_true
    (/PASSED: CNF had a reasonable startup time/ =~ response_s).should_not be_nil
    `crystal src/cnf-conformance.cr sample_coredns_cleanup`
  end

  it "'reasonable_startup_time' should fail if the cnf doesn't has a reasonable startup time(helm_directory)", tags: "reasonable_startup_time" do
    `crystal src/cnf-conformance.cr cnf_cleanup cnf-path=sample-cnfs/sample_envoy_slow_startup`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr reasonable_startup_time yml-file=sample-cnfs/sample_envoy_slow_startup/cnf-conformance.yml`
    $?.success?.should be_true
    (/FAILURE: CNF had a startup time of/ =~ response_s).should_not be_nil
    `crystal src/cnf-conformance.cr cnf_cleanup cnf-path=sample-cnfs/sample_envoy_slow_startup`
  end

  it "'reasonable_image_size' should pass if image is smaller than 5gb", tags: "reasonable_image_size" do
    begin
      `crystal src/cnf-conformance.cr sample_coredns_setup`
      response_s = `crystal src/cnf-conformance.cr reasonable_image_size verbose`
      puts response_s
      $?.success?.should be_true
      (/Image size is good/ =~ response_s).should_not be_nil
    ensure
      `crystal src/cnf-conformance.cr sample_coredns_cleanup`
    end
  end

  it "'reasonable_image_size' should fail if image is larger than 5gb", tags: "reasonable_image_size" do
    begin
      `crystal src/cnf-conformance.cr cnf_cleanup cnf-path=sample-cnfs/sample-large-cnf`
      `crystal src/cnf-conformance.cr cnf_setup cnf-path=sample-cnfs/sample-large-cnf deploy_with_chart=false`
      response_s = `crystal src/cnf-conformance.cr reasonable_image_size verbose`
      puts response_s
      $?.success?.should be_true
      (/Image size too large/ =~ response_s).should_not be_nil
    ensure
      `crystal src/cnf-conformance.cr cnf_cleanup cnf-path=sample-cnfs/sample-large-cnf`
    end
  end

end
