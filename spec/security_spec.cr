require "./spec_helper"
require "colorize"

describe CnfConformance do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr samples_cleanup`
    $?.success?.should be_true
    # `crystal src/cnf-conformance.cr setup`
    # $?.success?.should be_true
  end
  it "'privileged' should pass with a non-privileged cnf", tags: "privileged" do
    begin
      `crystal src/cnf-conformance.cr sample_coredns_setup`
      $?.success?.should be_true
      response_s = `crystal src/cnf-conformance.cr privileged verbose`
      puts response_s
      $?.success?.should be_true
      (/Found privileged containers.*coredns/ =~ response_s).should be_nil
    ensure
      `crystal src/cnf-conformance.cr sample_coredns_cleanup`
    end
  end
  it "'privileged' should fail on a non-whitelisted, privileged cnf", tags: "privileged" do
    begin
      `crystal src/cnf-conformance.cr sample_privileged_cnf_non_whitelisted_setup`
      $?.success?.should be_true
      response_s = `crystal src/cnf-conformance.cr privileged verbose`
      puts response_s
      $?.success?.should be_true
      (/Found privileged containers.*coredns/ =~ response_s).should_not be_nil
    ensure
      `crystal src/cnf-conformance.cr sample_privileged_cnf_non_whitelisted_cleanup`
    end
  end
  it "'privileged' should pass on a whitelisted, privileged cnf", tags: "privileged" do
    begin
      `crystal src/cnf-conformance.cr sample_privileged_cnf_whitelisted_setup`
      $?.success?.should be_true
      response_s = `crystal src/cnf-conformance.cr privileged verbose`
      puts response_s
      $?.success?.should be_true
      (/Found privileged containers.*coredns/ =~ response_s).should be_nil
    ensure
      `crystal src/cnf-conformance.cr sample_privileged_cnf_whitelisted_cleanup`
    end
  end
end
