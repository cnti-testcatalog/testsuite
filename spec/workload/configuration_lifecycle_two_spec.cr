require "../spec_helper"
require "../../src/tasks/utils/kubectl_client.cr"
require "colorize"

describe CnfConformance do
  before_all do
    LOGGING.debug `pwd` 
    LOGGING.debug `echo $KUBECONFIG`

    `./cnf-conformance setup`
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
    `./cnf-conformance configuration_file_setup`

    # `./cnf-conformance setup`
    # $?.success?.should be_true
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
      LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-conformance.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-conformance hardcoded_ip_addresses_in_k8s_runtime_configuration verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: No hard-coded IP addresses found in the runtime K8s configuration/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cleanup_sample_coredns`
    end
  end
  it "'secrets_used' should pass when secrets are provided as volumes and used by a container", tags: "secrets_used" do
    begin
      LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample_secret_volume/cnf-conformance.yml verbose `
      $?.success?.should be_true
      response_s = `./cnf-conformance secrets_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Secret Volume found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample_secret_volume verbose`
    end
  end

  it "'secrets_used' should fail when secrets are provided as volumes and not mounted by a container", tags: "secrets_used" do
    begin
      LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample_unmounted_secret_volume/cnf-conformance.yml verbose wait_count=0 `
      $?.success?.should be_true
      response_s = `./cnf-conformance secrets_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILURE: Secret Volume not found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample_unmounted_secret_volume verbose`
    end
  end

  it "'secrets_used' should pass when secrets are provided as environment variables and used by a container", tags: "secrets_used" do
    begin
      LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample_secret_env/cnf-conformance.yml verbose `
      $?.success?.should be_true
      response_s = `./cnf-conformance secrets_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Secret Volume found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample_secret_env verbose`
    end
  end

  it "'secrets_used' should fail when no secret volumes are mounted or no container secrets are provided`", tags: "secrets_used" do
    begin
      LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-conformance.yml verbose wait_count=0 `
      $?.success?.should be_true
      response_s = `./cnf-conformance secrets_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILURE: Secret Volume not found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample_coredns verbose`
    end
  end

  # # 1. test 1 fails buecase the sample_coredns helm chart configmap is not immutable
  # # 2. copay that sample_coredns cnf  and and make the config map immutable rename it and make sure test passes

  it "'immutable_configmap' fail without immutable configmaps", tags: "immutable_configmap" do
    begin
      `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-conformance.yml deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-conformance immutable_configmap verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILURE: Found mutable configmap/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-conformance.yml deploy_with_chart=false`
    end
  end

  it "'immutable_configmap' fail with only some immutable configmaps", tags: "immutable_configmap" do
    begin
      `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-conformance.yml deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-conformance immutable_configmap verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILURE: Found mutable configmap/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-config=./sample-cnfs/sample_immutable_configmap_some/cnf-conformance.yml deploy_with_chart=false`
    end
  end

  it "'immutable_configmap' should pass with all immutable configmaps", tags: "immutable_configmap" do
    begin
      LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample_immutable_configmap_all/cnf-conformance.yml deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-conformance immutable_configmap verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: All volume or container mounted configmaps immutable/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-conformance cnf_cleanup cnf-config=./sample-cnfs/sample_immutable_configmap_all/cnf-conformance.yml deploy_with_chart=false`
    end
  end


  it "'immutable_configmap' should pass with all immutable configmaps with env mounted", tags: "immutable_configmap" do
    begin
      LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample_immutable_configmap_all_plus_env/cnf-conformance.yml deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-conformance immutable_configmap verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: All volume or container mounted configmaps immutable/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-conformance cnf_cleanup cnf-config=./sample-cnfs/sample_immutable_configmap_all/cnf-conformance.yml deploy_with_chart=false`
    end
  end

  it "'immutable_configmap' should fail with a mutable env mounted configmap", tags: "immutable_configmap" do
    begin
      LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample_immutable_configmap_all_plus_env_but_fail/cnf-conformance.yml deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-conformance immutable_configmap verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILURE: Found mutable configmap/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-conformance cnf_cleanup cnf-config=./sample-cnfs/sample_immutable_configmap_all/cnf-conformance.yml deploy_with_chart=false`
    end
  end

end
