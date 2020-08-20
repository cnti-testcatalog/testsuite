require "./../spec_helper"
require "colorize"

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
  it "'platform:*' should not error out when no cnf is installed" do
    response_s = `./cnf-conformance cleanup`
    response_s = `./cnf-conformance platform:oci_compliant`
    LOGGING.info response_s
    puts response_s
    (/No cnf_conformance.yml found/ =~ response_s).should be_nil
  end
  it "'k8s_conformance' should pass if the sonobuoy tests pass" do
    response_s = `./cnf-conformance k8s_conformance`
    LOGGING.info response_s
    (/PASSED: K8s conformance test has no failures/ =~ response_s).should_not be_nil
  end
end

