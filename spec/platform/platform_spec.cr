require "./../spec_helper"
require "colorize"

describe "Platform" do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
    `./cnf-conformance setup`
    $?.success?.should be_true
    `./cnf-conformance sample_coredns_with_wait_setup`
    $?.success?.should be_true
  end
  it "'k8s_conformance' should pass if the sonobuoy tests pass" do
    response_s = `./cnf-conformance k8s_conformance`
    puts response_s
    (/PASSED: K8s conformance test has no failures/ =~ response_s).should_not be_nil
  end
end

