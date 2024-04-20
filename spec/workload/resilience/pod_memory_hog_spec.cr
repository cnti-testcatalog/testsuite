require "../../spec_helper"
require "colorize"
require "../../../src/tasks/utils/utils.cr"
require "helm"
require "file_utils"
require "sam"

describe "Resilience pod memory hog Chaos" do
  before_all do
    `./cnf-testsuite setup`
    `./cnf-testsuite configuration_file_setup`
    $?.success?.should be_true
  end

  it "'pod_memory_hog' A 'Good' CNF should not crash when pod memory hog occurs", tags: ["pod_memory_hog"]  do
    begin
      install_log = `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      LOGGING.info = install_log
      $?.success?.should be_true
      response_s = `./cnf-testsuite pod_memory_hog verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: pod_memory_hog chaos test passed/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      $?.success?.should be_true
      `./cnf-testsuite uninstall_litmus`
      $?.success?.should be_true
    end
  end
end
