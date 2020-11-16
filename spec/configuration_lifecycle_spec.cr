require "./spec_helper"
require "colorize"

describe CnfConformance do
  before_all do
    LOGGING.debug `pwd` 
    LOGGING.debug `echo $KUBECONFIG`

    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
    `./cnf-conformance configuration_file_setup`

    # `./cnf-conformance setup`
    # $?.success?.should be_true
  end

  it "'ip_addresses' should pass when no uncommented ip addresses are found in helm chart source", tags: "happy-path"  do
    begin
      `./cnf-conformance sample_coredns_source_setup verbose`
      $?.success?.should be_true
      response_s = `./cnf-conformance ip_addresses verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: No IP addresses found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance sample_coredns_source_cleanup verbose`
    end
  end
  it "'liveness' should pass when livenessProbe is set", tags: ["liveness", "happy-path"]  do
    begin
      `./cnf-conformance sample_coredns`
      $?.success?.should be_true
      response_s = `./cnf-conformance liveness verbose`
      LOGGING.info response_s
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
      LOGGING.info response_s
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
      LOGGING.info response_s
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
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILURE: No readinessProbe found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance sample_coredns_bad_liveness_cleanup`
    end
  end

  test_names = ["rolling_update", "rolling_downgrade", "rolling_version_change"]
  test_names.each do |tn|
    it "'#{tn}' should pass when valid version is given", tags: ["#{tn}", "happy-path"]  do
      begin
        LOGGING.info `./cnf-conformance sample_coredns`
        $?.success?.should be_true
        response_s = `./cnf-conformance #{tn} verbose`
        LOGGING.info response_s
        $?.success?.should be_true
        (/Passed/ =~ response_s).should_not be_nil
      ensure
        `./cnf-conformance cleanup_sample_coredns`
      end
    end
    it "'#{tn}' should fail when invalid version is given", tags: "#{tn}" do
      begin
        LOGGING.info `./cnf-conformance sample_coredns`
        $?.success?.should be_true
        response_s = `./cnf-conformance #{tn} verbose version_tag=this_is_not_real_version`
        LOGGING.info response_s
        $?.success?.should be_true
        (/Failed/ =~ response_s).should_not be_nil
      ensure
        `./cnf-conformance cleanup_sample_coredns`
      end
    end
  end

  it "'rollback' should pass ", tags: ["rollback", "happy-path"]  do
    begin
      LOGGING.info `./cnf-conformance sample_coredns`
      $?.success?.should be_true
      response_s = `./cnf-conformance rollback verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Passed/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cleanup_sample_coredns`
    end
  end

  # TODO: figure out failing test for rollback

  it "'nodeport_not_used' should fail when a node port is being used", tags: "nodeport_not_used" do
    begin
      `./cnf-conformance cnf_setup cnf-path=sample-cnfs/sample_nodeport deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-conformance nodeport_not_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILURE: NodePort is being used/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample_nodeport deploy_with_chart=false`
    end
  end
  it "'nodeport_not_used' should pass when a node port is not being used", tags: "nodeport_not_used" do
    begin
      `./cnf-conformance sample_coredns`
      $?.success?.should be_true
      response_s = `./cnf-conformance nodeport_not_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: NodePort is not used/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cleanup_sample_coredns`
    end
  end

  it "'hardcoded_ip_addresses_in_k8s_runtime_configuration' should fail when a hardcoded ip is found in the K8s configuration", tags: "hardcoded_ip_addresses_in_k8s_runtime_configuration" do
    begin
      `./cnf-conformance cnf_setup cnf-path=sample-cnfs/sample_coredns_hardcoded_ips deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `LOG_LEVEL=info ./cnf-conformance hardcoded_ip_addresses_in_k8s_runtime_configuration verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILURE: Hard-coded IP addresses found in the runtime K8s configuration/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample_coredns_hardcoded_ips deploy_with_chart=false`
    end
  end
  it "'hardcoded_ip_addresses_in_k8s_runtime_configuration' should pass when no ip addresses are found in the K8s configuration", tags: "hardcoded_ip_addresses_in_k8s_runtime_configuration" do
    begin
      `./cnf-conformance sample_coredns`
      $?.success?.should be_true
      response_s = `./cnf-conformance hardcoded_ip_addresses_in_k8s_runtime_configuration verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: No hard-coded IP addresses found in the runtime K8s configuration/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cleanup_sample_coredns`
    end
  end

end
