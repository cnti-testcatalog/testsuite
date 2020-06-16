require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "Statelessness" do
  before_all do
    `./cnf-conformance configuration_file_setup`
  end

  it "'volume_hostpath_not_found' should pass if the cnf doesn't have a hostPath volume", tags: ["volume_hostpath_not_found"]  do
    begin
      `./cnf-conformance cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-conformance.yml`
      $?.success?.should be_true
      response_s = `./cnf-conformance volume_hostpath_not_found verbose`
      puts "Status:  #{response_s}"
      (/PASSED: hostPath volumes not found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-conformance.yml`
      $?.success?.should be_true
    end
  end

  it "'volume_hostpath_not_found' should fail if the cnf has a hostPath volume", tags: ["volume_hostpath_not_found"]  do
    begin
      `./cnf-conformance cnf_setup cnf-config=sample-cnfs/sample-fragile-state/cnf-conformance.yml deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-conformance volume_hostpath_not_found verbose`
      (/FAILURE: hostPath volumes found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-config=sample-cnfs/sample-fragile-state/cnf-conformance.yml deploy_with_chart=false`
      $?.success?.should be_true
    end
  end
end
