require "./spec_helper"
require "colorize"

describe CnfConformance do
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

  after_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr samples_cleanup`
    $?.success?.should be_true
  end

  it "'all' should run the whole test suite" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    response_s = `crystal src/cnf-conformance.cr all verbose`
    puts response_s
    $?.success?.should be_true
    (/PASSED: Helm readiness probe found/ =~ response_s).should_not be_nil
    (/PASSED: Helm liveness probe/ =~ response_s).should_not be_nil
    (/Lint Passed/ =~ response_s).should_not be_nil
    (/PASSED: Replicas increased to 3/ =~ response_s).should_not be_nil
    (/PASSED: Replicas decreased to 1/ =~ response_s).should_not be_nil
    (/Final score:/ =~ response_s).should_not be_nil
  end

  it "'scalability' should run all of the scalability tests" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    response_s = `crystal src/cnf-conformance.cr setup`
    puts response_s
    response_s = `crystal src/cnf-conformance.cr scalability`
    puts response_s
      $?.success?.should be_true
    (/PASSED: Replicas increased to 3/ =~ response_s).should_not be_nil
    (/PASSED: Replicas decreased to 1/ =~ response_s).should_not be_nil
  end


end
