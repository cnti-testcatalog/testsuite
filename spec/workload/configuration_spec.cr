require "../spec_helper"
require "kubectl_client"
require "colorize"

describe CnfTestSuite do
  before_all do
    LOGGING.debug `pwd`
    LOGGING.debug `echo $KUBECONFIG`

    `./cnf-testsuite setup`
    `./cnf-testsuite samples_cleanup`
    $?.success?.should be_true
    `./cnf-testsuite configuration_file_setup`

    # `./cnf-testsuite setup`
    # $?.success?.should be_true
  end


  it "'versioned_tag' should pass when a cnf has image tags that are all versioned", tags: ["versioned_tag"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `LOG_LEVEL=info ./cnf-testsuite versioned_tag verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Container images use versioned tags/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
      LOGGING.info `./cnf-testsuite uninstall_opa`
    end
  end

  it "'versioned_tag' should fail when a cnf has image tags that are not versioned", tags: ["versioned_tag"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/k8s-sidecar-container-pattern/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `LOG_LEVEL=info ./cnf-testsuite versioned_tag verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Container images do not use versioned tags/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/k8s-sidecar-container-pattern/cnf-testsuite.yml`
      LOGGING.info `./cnf-testsuite uninstall_opa`
    end
  end

  it "'liveness' should pass when livenessProbe is set", tags: ["liveness"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/k8s-multiple-deployments/cnf-testsuite.yml deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `LOG_LEVEL=debug ./cnf-testsuite liveness verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Helm liveness probe/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/k8s-multiple-deployments/cnf-testsuite.yml deploy_with_chart=false `
    end
  end

  it "'liveness' should fail when livenessProbe is not set", tags: ["liveness"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns_bad_liveness/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite liveness verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: No livenessProbe found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite sample_coredns_bad_liveness_cleanup`
    end
  end

  it "'readiness' should pass when readinessProbe is set", tags: ["readiness"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/k8s-multiple-deployments/cnf-testsuite.yml deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `LOG_LEVEL=debug ./cnf-testsuite readiness verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Helm readiness probe/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/k8s-multiple-deployments/cnf-testsuite.yml deploy_with_chart=false `
    end
  end

  it "'readiness' should fail when readinessProbe is not set", tags: ["readiness"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns_bad_liveness/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite readiness verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: No readinessProbe found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite sample_coredns_bad_liveness_cleanup`
    end
  end

  it "'rolling_update' should pass when valid version is given", tags: ["rolling_update"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml verbose`
      $?.success?.should be_true
      response_s = `./cnf-testsuite rolling_update verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Passed/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml`
    end
  end

  it "'rolling_update' should fail when invalid version is given", tags: ["rolling_update"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_rolling_invalid_version/cnf-testsuite.yml deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-testsuite rolling_update verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Failed/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_rolling_invalid_version/cnf-testsuite.yml deploy_with_chart=false`
    end
  end

  it "'rolling_downgrade' should pass when valid version is given", tags: ["rolling_downgrade"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      retry_limit = 5 
      retries = 1
      response_s = "" 
      until (/Passed/ =~ response_s) || retries > retry_limit
        LOGGING.info "rolling_downgrade retry: #{retries}"
        sleep 1.0
        response_s = `./cnf-testsuite rolling_downgrade verbose`
        retries = retries + 1
      end
      LOGGING.info response_s
      $?.success?.should be_true
      (/Passed/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml`
    end
  end

  it "'rolling_downgrade' should fail when invalid version is given", tags: ["rolling_downgrade"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_rolling_invalid_version/cnf-testsuite.yml deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-testsuite rolling_downgrade verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Failed/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_rolling_invalid_version/cnf-testsuite.yml deploy_with_chart=false`
    end
  end

  it "'rolling_version_change' should pass when valid version is given", tags: ["rolling_version_change"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite rolling_version_change verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Passed/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml`
    end
  end

  it "'rolling_version_change' should fail when invalid version is given", tags: ["rolling_version_change"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_rolling_invalid_version/cnf-testsuite.yml deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-testsuite rolling_version_change verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Failed/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_rolling_invalid_version/cnf-testsuite.yml deploy_with_chart=false`
    end
  end

  it "'rollback' should pass ", tags: ["rollback"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite rollback verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Passed/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml`
    end
  end

  # TODO: figure out failing test for rollback

  it "'nodeport_not_used' should fail when a node port is being used", tags: ["nodeport_not_used"] do
    begin
      `./cnf-testsuite cnf_setup cnf-path=sample-cnfs/sample_nodeport deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-testsuite nodeport_not_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: NodePort is being used/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_nodeport deploy_with_chart=false`
    end
  end

  it "'nodeport_not_used' should pass when a node port is not being used", tags: ["nodeport_not_used"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite nodeport_not_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: NodePort is not used/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
    end
  end

  it "'hostport_not_used' should fail when a node port is being used", tags: ["hostport_not_used"] do
    begin
      `./cnf-testsuite cnf_setup cnf-path=sample-cnfs/sample_hostport deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-testsuite hostport_not_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: HostPort is being used/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_hostport deploy_with_chart=false`
    end
  end

  it "'hostport_not_used' should pass when a node port is not being used", tags: ["hostport_not_used"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite hostport_not_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: HostPort is not used/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
    end
  end

  it "'ip_addresses' should pass when no uncommented ip addresses are found in helm chart source", tags: ["ip_addresses"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf-source/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite ip_addresses verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: No IP addresses found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite sample_coredns_source_cleanup verbose`
    end
  end

  it "'hardcoded_ip_addresses_in_k8s_runtime_configuration' should fail when a hardcoded ip is found in the K8s configuration", tags: ["ip_addresses"] do
    begin
      `./cnf-testsuite cnf_setup cnf-path=sample-cnfs/sample_coredns_hardcoded_ips deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `LOG_LEVEL=info ./cnf-testsuite hardcoded_ip_addresses_in_k8s_runtime_configuration verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Hard-coded IP addresses found in the runtime K8s configuration/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_coredns_hardcoded_ips deploy_with_chart=false`
    end
  end

  it "'hardcoded_ip_addresses_in_k8s_runtime_configuration' should pass when no ip addresses are found in the K8s configuration", tags: ["ip_addresses"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite hardcoded_ip_addresses_in_k8s_runtime_configuration verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: No hard-coded IP addresses found in the runtime K8s configuration/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
    end
  end

  it "'secrets_used' should pass when secrets are provided as volumes and used by a container", tags: ["secrets"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_secret_volume/cnf-testsuite.yml verbose `
      $?.success?.should be_true
      response_s = `./cnf-testsuite secrets_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Secrets defined and used/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_secret_volume verbose`
    end
  end

  it "'secrets_used' should be skipped when secrets are provided as volumes and not mounted by a container", tags: ["secrets"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_unmounted_secret_volume/cnf-testsuite.yml verbose wait_count=0 `
      $?.success?.should be_true
      response_s = `./cnf-testsuite secrets_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/SKIPPED: Secrets not used/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_unmounted_secret_volume verbose`
    end
  end

  it "'secrets_used' should pass when secrets are provided as environment variables and used by a container", tags: ["secrets"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_secret_env/cnf-testsuite.yml verbose `
      $?.success?.should be_true
      response_s = `./cnf-testsuite secrets_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Secrets defined and used/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_secret_env verbose`
    end
  end

  it "'secrets_used' should skip when secrets are not referenced as environment variables by a container", tags: ["secrets"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_secret_env_no_ref/cnf-testsuite.yml wait_count=2 verbose`
      $?.success?.should be_true
      response_s = `./cnf-testsuite secrets_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/SKIPPED: Secrets not used/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_secret_env verbose`
    end
  end

  it "'secrets_used' should be skipped when no secret volumes are mounted or no container secrets are provided (secrets ignored)`", tags: ["secrets"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml verbose wait_count=0 `
      $?.success?.should be_true
      response_s = `./cnf-testsuite secrets_used verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/SKIPPED: Secrets not used/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_coredns verbose`
    end
  end

  it "'immutable_configmap' fail with some mutable configmaps in container env or volume mount", tags: ["immutable_configmap"] do
    begin
      `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/ndn-mutable-configmap deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-testsuite immutable_configmap verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Found mutable configmap/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/ndn-mutable-configmap deploy_with_chart=false`
    end
  end

  it "'immutable_configmap' pass with all immutable configmaps in container env or volume mounts", tags: ["immutable_configmap"] do
    begin
      `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/ndn-immutable-configmap deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-testsuite immutable_configmap verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: All volume or container mounted configmaps immutable/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/ndn-immutable-configmap deploy_with_chart=false`
    end
  end

  it "'require_labels' should fail if a cnf does not have the app.kubernetes.io/name label", tags: ["require_labels"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_nonroot/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite require_labels verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Pods should have the app.kubernetes.io\/name label/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_nonroot/cnf-testsuite.yml`
    end
  end

  it "'require_labels' should pass if a cnf has the app.kubernetes.io/name label", tags: ["require_labels"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite require_labels verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Pods have the app.kubernetes.io\/name label/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
    end
  end

  it "'default_namespace' should fail if a cnf creates resources in the default namespace", tags: ["default_namespace"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns`
      $?.success?.should be_true
      response_s = `./cnf-testsuite default_namespace verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Resources are created in the default namespace/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_coredns`
      KubectlClient::Utils.wait_for_terminations()
    end
  end

  it "'default_namespace' should pass if a cnf does not create resources in the default namespace", tags: ["default_namespace"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_latest_tag`
      $?.success?.should be_true
      response_s = `./cnf-testsuite default_namespace verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: default namespace is not being used/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_latest_tag`
      KubectlClient::Utils.wait_for_terminations()
    end
  end

  it "'latest_tag' should fail if a cnf has containers that use images with the latest tag", tags: ["latest_tag"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_latest_tag`
      $?.success?.should be_true
      response_s = `./cnf-testsuite latest_tag verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Container images are using the latest tag/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_latest_tag`
    end
  end

  it "'latest_tag' should pass if a cnf does not have containers that use images with the latest tag", tags: ["latest_tag"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_nonroot`
      $?.success?.should be_true
      response_s = `./cnf-testsuite latest_tag verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Container images are not using the latest tag/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_nonroot`
    end
  end

  # Commenting because the test has now been marked as a POC
  #
  # it "'alpha_k8s_apis' should pass with a CNF that does not make use of alpha k8s APIs", tags: ["apisnoop"] do
  #   begin
  #     Log.info { `./cnf-testsuite cnf_setup cnf-path=./sample-cnfs/sample_coredns` }
  #     $?.success?.should be_true
  #     response_s = `./cnf-testsuite alpha_k8s_apis verbose`
  #     Log.info { response_s }
  #     $?.success?.should be_true
  #     (/PASSED: CNF does not use Kubernetes alpha APIs/ =~ response_s).should_not be_nil
  #   ensure
  #     Log.info { `./cnf-testsuite cnf_cleanup cnf-path=./sample-cnfs/sample_coredns` }
  #   end
  # end

end
