require "./spec_helper"
require "colorize"

describe CnfConformance do
 # TODO: Write tests
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr setup`
    $?.success?.should be_true
    # Helm chart deploys take a while to spin up
    sleep 15 

  end
  it "'all' should run the whole test suite" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    response_s = `crystal src/cnf-conformance.cr all`
    puts response_s
    $?.success?.should be_true
    (/PASSED: Helm readiness probe found/ =~ response_s).should_not be_nil
    (/PASSED: Helm liveness probe/ =~ response_s).should_not be_nil
    (/FAILURE: Helm not found in install script/ =~ response_s).should_not be_nil
    (/FAILURE: IP addresses found/ =~ response_s).should_not be_nil
    (/Lint Passed/ =~ response_s).should_not be_nil
    ((/PASSED: No privileged containers/ =~ response_s) || (/Found privileged containers/ =~ response_s)).should_not be_nil
    (/PASSED: Replicas increased to 3/ =~ response_s).should_not be_nil
    (/PASSED: Replicas decreased to 1/ =~ response_s).should_not be_nil
  end

  it "'scalability' should run all of the scalability tests" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    response_s = `crystal src/cnf-conformance.cr scalability`
    puts response_s
      $?.success?.should be_true
    (/PASSED: Replicas increased to 3/ =~ response_s).should_not be_nil
    (/PASSED: Replicas decreased to 1/ =~ response_s).should_not be_nil
  end
end
