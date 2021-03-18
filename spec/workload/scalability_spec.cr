require "../spec_helper"
require "../../src/tasks/utils/utils.cr"
require "colorize"

describe "Scalability" do
  before_all do
    `./cnf-conformance setup`
    $?.success?.should be_true
  end

  after_all do
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
  end

it "'scalability' should run all of the scalability tests", tags: "[scalability]"  do
    `./cnf-conformance samples_cleanup`
    response_s = `./cnf-conformance setup`
    LOGGING.info response_s
    # `./cnf-conformance sample_coredns_with_wait_setup`
    LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-conformance.yml verbose`
    $?.success?.should be_true
    response_s = `./cnf-conformance scalability`
    LOGGING.info response_s
    $?.success?.should be_true
    (/PASSED: Replicas increased to 3/ =~ response_s).should_not be_nil
    (/PASSED: Replicas decreased to 1/ =~ response_s).should_not be_nil
  end
end
