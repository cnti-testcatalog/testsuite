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
  it "'ip_addresses' should fail when ip addresses are found in source is set", tags: "liveness" do
    begin
      `crystal src/cnf-conformance.cr sample_coredns_source_setup`
      $?.success?.should be_true
      response_s = `crystal src/cnf-conformance.cr ip_addresses verbose`
      puts response_s
      $?.success?.should be_true
      (/FAILURE: IP addresses found/ =~ response_s).should_not be_nil
    ensure
      `crystal src/cnf-conformance.cr sample_coredns_source_cleanup verbose`
    end
  end
  it "'liveness' should pass when livenessProbe is set", tags: "liveness" do
    begin
      `crystal src/cnf-conformance.cr sample_coredns`
      $?.success?.should be_true
      response_s = `crystal src/cnf-conformance.cr liveness verbose`
      puts response_s
      $?.success?.should be_true
      (/PASSED: Helm liveness probe/ =~ response_s).should_not be_nil
    ensure
      `crystal src/cnf-conformance.cr cleanup_sample_coredns verbose`
    end
  end
  it "'liveness' should fail when livenessProbe is not set", tags: "liveness" do
    begin
      `crystal src/cnf-conformance.cr sample_coredns_bad_liveness`
      $?.success?.should be_true
      response_s = `crystal src/cnf-conformance.cr liveness verbose`
      puts response_s
      $?.success?.should be_true
      (/FAILURE: No livenessProbe found/ =~ response_s).should_not be_nil
    ensure
      `crystal src/cnf-conformance.cr sample_coredns_bad_liveness_cleanup`
    end
  end
  it "'readiness' should pass when readinessProbe is set", tags: "readiness" do
    begin
      `crystal src/cnf-conformance.cr sample_coredns`
      $?.success?.should be_true
      response_s = `crystal src/cnf-conformance.cr readiness verbose`
      puts response_s
      $?.success?.should be_true
      (/PASSED: Helm readiness probe/ =~ response_s).should_not be_nil
    ensure
      `crystal src/cnf-conformance.cr cleanup_sample_coredns verbose`
    end
  end
  it "'readiness' should fail when readinessProbe is not set", tags: "readiness" do
    begin
      `crystal src/cnf-conformance.cr sample_coredns_bad_liveness`
      $?.success?.should be_true
      response_s = `crystal src/cnf-conformance.cr readiness verbose`
      puts response_s
      $?.success?.should be_true
      (/FAILURE: No readinessProbe found/ =~ response_s).should_not be_nil
    ensure
      `crystal src/cnf-conformance.cr sample_coredns_bad_liveness_cleanup`
    end
  end
end
