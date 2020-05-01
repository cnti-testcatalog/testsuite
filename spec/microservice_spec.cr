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
  it "'image_size_large' should pass if image is smaller than 5gb" do
    begin
      `crystal src/cnf-conformance.cr sample_coredns_setup`
      response_s = `crystal src/cnf-conformance.cr image_size_large verbose`
      puts response_s
      $?.success?.should be_true
      (/Image size is good/ =~ response_s).should_not be_nil
    ensure
      `crystal src/cnf-conformance.cr sample_coredns_cleanup`
    end
  end

  it "'image_size_large' should fail if image is larger than 5gb" do
    begin
      `crystal src/cnf-conformance.cr cnf_cleanup cnf-path=sample-cnfs/sample-large-cnf`
      `crystal src/cnf-conformance.cr cnf_setup cnf-path=sample-cnfs/sample-large-cnf deploy_with_chart=false`
      response_s = `crystal src/cnf-conformance.cr image_size_large verbose`
      puts response_s
      $?.success?.should be_true
      (/Image size too large/ =~ response_s).should_not be_nil
    ensure
      `crystal src/cnf-conformance.cr cnf_cleanup cnf-path=sample-cnfs/sample-large-cnf`
    end
  end

end
