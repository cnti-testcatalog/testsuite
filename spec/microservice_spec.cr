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
    `./cnf-conformance samples_cleanup force=true`
    $?.success?.should be_true
    `./cnf-conformance configuration_file_setup`
    # `./cnf-conformance setup`
    # $?.success?.should be_true
  end

  it "'reasonable_startup_time' should pass if the cnf has a reasonable startup time(helm_directory)", tags: ["reasonable_startup_time", "happy-path", "test"]  do
    begin
      response_s = `./cnf-conformance reasonable_startup_time cnf-config=sample-cnfs/sample_coredns/cnf-conformance.yml`
      $?.success?.should be_true
      LOGGING.info response_s
      (/PASSED: CNF had a reasonable startup time/ =~ response_s).should_not be_nil
    ensure
      `kubectl delete -f sample-cnfs/sample_coredns/reasonable_startup_orig.yml`
      $?.success?.should be_true
    end
  end

  it "'reasonable_startup_time' should fail if the cnf doesn't has a reasonable startup time(helm_directory)", tags: "reasonable_startup_time" do
    begin
      response_s = `./cnf-conformance reasonable_startup_time cnf-config=sample-cnfs/sample_envoy_slow_startup/cnf-conformance.yml`
      $?.success?.should be_true
      LOGGING.info response_s
      (/FAILURE: CNF had a startup time higher/ =~ response_s).should_not be_nil
    ensure
      `kubectl delete -f sample-cnfs/sample_envoy_slow_startup/reasonable_startup_orig.yml`
      $?.success?.should be_true
      `./cnf-conformance cnf_cleanup cnf-config=sample-cnfs/sample_envoy_slow_startup/cnf-conformance.yml force=true`
      $?.success?.should be_true
    end
  end

  it "'reasonable_image_size' should pass if image is smaller than 5gb", tags: ["reasonable_image_size","happy-path"]  do
    begin
      `./cnf-conformance cleanup force=true`
      `./cnf-conformance sample_coredns_setup`
      response_s = `./cnf-conformance reasonable_image_size verbose`
      puts response_s
      $?.success?.should be_true
      (/Image size is good/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance sample_coredns_cleanup force=true`
    end
  end

  it "'reasonable_image_size' should fail if image is larger than 5gb", tags: "reasonable_image_size" do
    begin
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample-large-cnf force=true`
      `./cnf-conformance cnf_setup cnf-path=sample-cnfs/sample-large-cnf deploy_with_chart=false`
      response_s = `./cnf-conformance reasonable_image_size verbose`
      puts response_s
      $?.success?.should be_true
      (/Image size too large/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample-large-cnf force=true`
    end
  end

end
