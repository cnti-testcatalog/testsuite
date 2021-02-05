require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "Microservice" do
  before_all do
    # LOGGING.debug `pwd` 
    # LOGGING.debug `echo $KUBECONFIG`
    `./cnf-conformance samples_cleanup force=true`
    $?.success?.should be_true
    `./cnf-conformance configuration_file_setup`
    # `./cnf-conformance setup`
    # $?.success?.should be_true
  end

  it "'reasonable_startup_time' should pass if the cnf has a reasonable startup time(helm_directory)", tags: ["reasonable_startup_time", "happy-path"]  do
    begin
      response_s = `./cnf-conformance reasonable_startup_time destructive cnf-config=sample-cnfs/sample_coredns/cnf-conformance.yml`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: CNF had a reasonable startup time/ =~ response_s).should_not be_nil
    ensure
      `kubectl delete -f sample-cnfs/sample_coredns/reasonable_startup_orig.yml`
      `./cnf-conformance samples_cleanup force=true`
      $?.success?.should be_true
    end
  end

  it "'reasonable_startup_time' should fail if the cnf doesn't has a reasonable startup time(helm_directory)", tags: "reasonable_startup_time" do
    `./cnf-conformance cnf_cleanup cnf-config=sample-cnfs/sample_envoy_slow_startup/cnf-conformance.yml force=true`
      `kubectl delete -f sample-cnfs/sample_envoy_slow_startup/reasonable_startup_orig.yml`
    begin
      response_s = `./cnf-conformance reasonable_startup_time  destructive cnf-config=sample-cnfs/sample_envoy_slow_startup/cnf-conformance.yml verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILURE: CNF had a startup time of/ =~ response_s).should_not be_nil
    ensure
      `kubectl delete -f sample-cnfs/sample_envoy_slow_startup/reasonable_startup_orig.yml`
      $?.success?.should be_true
      `./cnf-conformance cnf_cleanup cnf-config=sample-cnfs/sample_envoy_slow_startup/cnf-conformance.yml force=true`
      $?.success?.should be_true
    end
  end

  it "'reasonable_image_size' should pass if image is smaller than 5gb", tags: ["reasonable_image_size","happy-path"]  do
    if ENV["PROTECTED_DOCKERHUB_USERNAME"]? && ENV["PROTECTED_DOCKERHUB_PASSWORD"]? && ENV["PROTECTED_DOCKERHUB_EMAIL"]?
         cnf="./sample-cnfs/sample_coredns_protected"
       else
         cnf="./sample-cnfs/sample-coredns-cnf"
    end
    LOGGING.info `./cnf-conformance cnf_setup cnf-path=#{cnf}`
    response_s = `./cnf-conformance reasonable_image_size verbose`
    LOGGING.info response_s
    $?.success?.should be_true
    (/Image size is good/ =~ response_s).should_not be_nil
  ensure
    LOGGING.info `./cnf-conformance cnf_cleanup cnf-path=#{cnf}`
  end

  it "'reasonable_image_size' should fail if image is larger than 5gb", tags: "reasonable_image_size" do
    `./cnf-conformance cnf_setup cnf-path=./sample-cnfs/sample_envoy_slow_startup wait_count=0`
    response_s = `./cnf-conformance reasonable_image_size verbose`
    LOGGING.info response_s
    $?.success?.should be_true
    (/Image size too large/ =~ response_s).should_not be_nil
  ensure
    `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample_envoy_slow_startup force=true`
  end
end
