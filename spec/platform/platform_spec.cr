require "./../spec_helper"
require "colorize"

describe "Platform" do
  it "'k8s_conformance' should pass if the sonobuoy tests pass" do
    response_s = `crystal src/cnf-conformance.cr k8s_conformance`
    puts response_s
    (/PASSED: K8s conformance test has no failures/ =~ response_s).should_not be_nil
  end
end

