require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "Setup" do
  before_each do
    `./cnf-testsuite cleanup`
    $?.success?.should be_true
  end

  after_each do
    `./cnf-testsuite cleanup`
    $?.success?.should be_true
  end

  it "'setup' should completely setup the cnf conformance environment before installing cnfs", tags: ["setup"]  do
    response_s = `./cnf-testsuite setup`
    LOGGING.info response_s
    $?.success?.should be_true
    (/Setup complete/ =~ response_s).should_not be_nil
  end

  it "'generate_config' should completely setup the cnf conformance environment before installing cnfs", tags: ["setup"]  do
    response_s = `./cnf-testsuite generate_config config-src=stable/coredns output-file=./cnf-conformance-test.yml`
    LOGGING.info response_s
    $?.success?.should be_true
    # (/Setup complete/ =~ response_s).should_not be_nil

    yaml = File.open("./cnf-conformance-test.yml") do |file|
      YAML.parse(file)
    end
    LOGGING.debug "test yaml: #{yaml}"
    LOGGING.info `cat ./cnf-conformance-test.yml`
    (yaml["container_names"][0]["name"] == "coredns").should be_true
    (yaml["container_names"][0]["rolling_update_test_tag"] == "1.7.1").should be_true
    (yaml["container_names"][0]["rolling_downgrade_test_tag"] == "1.7.1").should be_true
    (yaml["container_names"][0]["rolling_version_change_test_tag"] == "1.7.1").should be_true
    (yaml["container_names"][0]["rollback_from_tag"] == "1.7.1").should be_true
  ensure
    `rm ./cnf-conformance-test.yml`
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup a cnf with a cnf-conformance.yml", tags: ["setup"]  do
    begin
      response_s = `./cnf-testsuite cnf_setup cnf-config=example-cnfs/coredns/cnf-conformance.yml`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Successfully setup coredns/ =~ response_s).should_not be_nil
    ensure

      response_s = `./cnf-testsuite cnf_cleanup cnf-config=example-cnfs/coredns/cnf-conformance.yml`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Successfully cleaned up/ =~ response_s).should_not be_nil
    end
  end
  it "'cnf_setup/cnf_cleanup' should work with cnf-conformance.yml that has no directory associated with it", tags: ["setup"] do
    begin
      #TODO force cnfs/<name> to be deployment name and not the directory name
      response_s = `./cnf-testsuite cnf_setup cnf-config=spec/fixtures/cnf-conformance.yml verbose`
      LOGGING.info("response_s: #{response_s}")
      $?.success?.should be_true
      (/Successfully setup coredns/ =~ response_s).should_not be_nil
    ensure

      response_s = `./cnf-testsuite cnf_cleanup cnf-path=spec/fixtures/cnf-conformance.yml verbose`
      LOGGING.info("response_s: #{response_s}")
      $?.success?.should be_true
      (/Successfully cleaned up/ =~ response_s).should_not be_nil
    end

  end
end
