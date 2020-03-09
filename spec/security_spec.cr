require "./spec_helper"
require "colorize"

describe CnfConformance do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    # `crystal src/cnf-conformance.cr cleanup`
    # $?.success?.should be_true
    # `crystal src/cnf-conformance.cr setup`
    # $?.success?.should be_true
    # Helm chart deploys take a while to spin up
    # TODO put sleep in setup installs
    # sleep 15 

  end
  it "'privileged' should fail on a non-whitelisted, privileged cnf" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr sample_coredns_cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr sample_privileged_cnf_setup`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr privileged verbose`
    puts response_s
    $?.success?.should be_true
    (/Lint Failed/ =~ response_s).should_not be_nil
    `crystal src/cnf-conformance.cr sample_privileged_cnf_cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr sample_coredns_setup`
    $?.success?.should be_true
  end
end
