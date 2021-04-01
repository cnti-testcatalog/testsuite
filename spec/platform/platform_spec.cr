require "./../spec_helper"
require "colorize"

describe "Platform" do
  before_all do
    # LOGGING.debug `pwd` 
    # LOGGING.debug `echo $KUBECONFIG`
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
    LOGGING.info `./cnf-conformance setup`
    $?.success?.should be_true
    # LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-conformance.yml verbose`
    # $?.success?.should be_true
  end
  it "'platform:*' should not error out when no cnf is installed", tags: ["platform"] do
    response_s = `./cnf-conformance cleanup`
    response_s = `./cnf-conformance platform:oci_compliant`
    LOGGING.info response_s
    puts response_s
    (/No cnf_conformance.yml found/ =~ response_s).should be_nil
  end
  it "'platform' should not run prerequisites that are prefixed with a ~", tags: ["platform"] do
    response_s = `./cnf-conformance cleanup`
    # response_s = `./cnf-conformance platform`
    stdout = IO::Memory.new
    stderror = IO::Memory.new
    # Capture all output from sonobuoy
    process = Process.new("./cnf-conformance", ["platform", "~k8s_conformance"], output: stdout, error: stderror)
    status = process.wait
    response_s = stdout.to_s
    error = stderror.to_s
    LOGGING.info "error: #{error}"
    LOGGING.info "response #{response_s}"
    (/kind=namespace namespace=sonobuoy/ =~ (response_s + error)).should be_nil
  end
  it "'k8s_conformance' should pass if the sonobuoy tests pass", tags: ["platform"] do
    response_s = `./cnf-conformance k8s_conformance`
    LOGGING.info response_s
    (/PASSED: K8s conformance test has no failures/ =~ response_s).should_not be_nil
  end
end

