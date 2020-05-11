require "./spec_helper"
require "colorize"

describe CnfConformance do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`

    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
    `./cnf-conformance configuration_file_setup`

    # `./cnf-conformance setup`
    # $?.success?.should be_true
  end
  it "'ip_addresses' should fail when ip addresses are found in the source that is set", tags: "happy-path"  do
    begin
      `./cnf-conformance sample_coredns_source_setup verbose`
      $?.success?.should be_true
      response_s = `./cnf-conformance ip_addresses verbose`
      puts response_s
      $?.success?.should be_true
      (/FAILURE: IP addresses found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance sample_coredns_source_cleanup verbose`
    end
  end
  it "'liveness' should pass when livenessProbe is set", tags: ["liveness", "happy-path"]  do
    begin
      `./cnf-conformance sample_coredns`
      $?.success?.should be_true
      response_s = `./cnf-conformance liveness verbose`
      puts response_s
      $?.success?.should be_true
      (/PASSED: Helm liveness probe/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cleanup_sample_coredns verbose`
    end
  end
  it "'liveness' should fail when livenessProbe is not set", tags: "liveness" do
    begin
      `./cnf-conformance sample_coredns_bad_liveness`
      $?.success?.should be_true
      response_s = `./cnf-conformance liveness verbose`
      puts response_s
      $?.success?.should be_true
      (/FAILURE: No livenessProbe found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance sample_coredns_bad_liveness_cleanup`
    end
  end
  it "'readiness' should pass when readinessProbe is set", tags: ["readiness","happy-path"]  do
    begin
      `./cnf-conformance sample_coredns`
      $?.success?.should be_true
      response_s = `./cnf-conformance readiness verbose`
      puts response_s
      $?.success?.should be_true
      (/PASSED: Helm readiness probe/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cleanup_sample_coredns verbose`
    end
  end
  it "'readiness' should fail when readinessProbe is not set", tags: "readiness" do
    begin
      `./cnf-conformance sample_coredns_bad_liveness`
      $?.success?.should be_true
      response_s = `./cnf-conformance readiness verbose`
      puts response_s
      $?.success?.should be_true
      (/FAILURE: No readinessProbe found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance sample_coredns_bad_liveness_cleanup`
    end
  end
  it "'rolling_update' should pass when valid version is given", tags: ["rolling_update", "happy-path"]  do
    begin
      `./cnf-conformance sample_coredns`
      $?.success?.should be_true
      response_s = `./cnf-conformance rolling_update verbose`
      puts response_s
      $?.success?.should be_true
      (/Rolling Update Passed/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cleanup_sample_coredns`
    end
  end
  it "'rolling_update' should fail when invalid version is given", tags: "rolling_update" do
    begin
      `./cnf-conformance sample_coredns`
      $?.success?.should be_true
      response_s = `./cnf-conformance rolling_update verbose version_tag=this_is_not_real_version`
      puts response_s
      $?.success?.should be_true
      (/Rolling Update Failed/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cleanup_sample_coredns`
    end
  end
  it "'nodeport_not_used' should fail when a node port is being used", tags: "nodeport_not_used" do
    begin
      `crystal src/cnf-conformance.cr cnf_setup cnf-path=sample-cnfs/sample_nodeport deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `crystal src/cnf-conformance.cr nodeport_not_used verbose`
      puts response_s
      $?.success?.should be_true
      (/FAILURE: NodePort is being used/ =~ response_s).should_not be_nil
    ensure
      `crystal src/cnf-conformance.cr cnf_cleanup cnf-path=sample-cnfs/sample_nodeport deploy_with_chart=false`
    end
  end
  it "'nodeport_not_used' should pass when a node port is not being used", tags: "nodeport_not_used" do
    begin
      `crystal src/cnf-conformance.cr sample_coredns`
      $?.success?.should be_true
      response_s = `crystal src/cnf-conformance.cr nodeport_not_used verbose`
      puts response_s
      $?.success?.should be_true
      (/PASSED: NodePort is not used/ =~ response_s).should_not be_nil
    ensure
      `crystal src/cnf-conformance.cr cleanup_sample_coredns`
    end
  end
end
