require "./../spec_helper"
require "colorize"

describe "Platform" do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr samples_cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr setup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr sample_coredns_with_wait_setup`
    $?.success?.should be_true
  end
  it "'k8s_conformance' should pass if the sonobuoy tests pass" do
    response_s = `crystal src/cnf-conformance.cr k8s_conformance`
    puts response_s
    (/PASSED: K8s conformance test has no failures/ =~ response_s).should_not be_nil
  end
end

