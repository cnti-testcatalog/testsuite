require "./../spec_helper"
require "colorize"
require "./../../src/tasks/utils/utils.cr"

describe "Platform" do
  before_all do
    # LOGGING.debug `pwd` 
    # LOGGING.debug `echo $KUBECONFIG`
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
    `./cnf-conformance setup`
    $?.success?.should be_true
    `./cnf-conformance sample_coredns_with_wait_setup`
    $?.success?.should be_true
  end
  it "'node_failure' should pass if chaos_mesh node_failure tests prove the platform is resilient" do
    if check_destructive
      puts "Tests running in destructive mode".colorize(:red) 
      response_s = `./cnf-conformance platform:node_failure poc destructive`
      LOGGING.info response_s
      (/(PASSED: Node came back online)/ =~ response_s).should_not be_nil
    else
      response_s = `./cnf-conformance platform:node_failure poc`
      LOGGING.info response_s
      (/(PASSED: Nodes are resilient|Skipped)/ =~ response_s).should_not be_nil
    end
  end
end

