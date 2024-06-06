require "../spec_helper"
require "kubectl_client"
require "colorize"
require "../../src/tasks/utils/utils.cr"

describe CnfTestSuite do
  before_all do
    result = ShellCmd.run("pwd")
    Log.debug { result[:output] }
    result = ShellCmd.run("echo $KUBECONFIG")
    Log.debug { result[:output] }

    result = ShellCmd.run_testsuite("setup")
    result = ShellCmd.run_testsuite("samples_cleanup")
    result[:status].success?.should be_true
    result = ShellCmd.run_testsuite("configuration_file_setup")

  end

  it "'liveness' should pass when livenessProbe is set", tags: ["liveness"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/k8s-multiple-deployments/cnf-testsuite.yml deploy_with_chart=false")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("liveness verbose", cmd_prefix:"LOG_LEVEL=debug")
      result[:status].success?.should be_true
      (/(PASSED).*(Helm liveness probe)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/k8s-multiple-deployments/cnf-testsuite.yml deploy_with_chart=false ")
    end
  end

  it "'liveness' should fail when livenessProbe is not set", tags: ["liveness"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_coredns_bad_liveness/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("liveness verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(No livenessProbe found)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("sample_coredns_bad_liveness_cleanup")
    end
  end

  it "'readiness' should pass when readinessProbe is set", tags: ["readiness"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/k8s-multiple-deployments/cnf-testsuite.yml deploy_with_chart=false")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("readiness verbose", cmd_prefix: "LOG_LEVEL=debug")
      result[:status].success?.should be_true
      (/(PASSED).*(Helm readiness probe)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/k8s-multiple-deployments/cnf-testsuite.yml deploy_with_chart=false ")
    end
  end

  it "'readiness' should fail when readinessProbe is not set", tags: ["readiness"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_coredns_bad_liveness/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("readiness verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(No readinessProbe found)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("sample_coredns_bad_liveness_cleanup")
    end
  end

  it "'rolling_update' should pass when valid version is given", tags: ["rolling_update"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml verbose")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("rolling_update verbose")
      result[:status].success?.should be_true
      (/Passed/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml")
    end
  end

  it "'rolling_update' should fail when invalid version is given", tags: ["rolling_update"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_rolling_invalid_version/cnf-testsuite.yml deploy_with_chart=false")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("rolling_update verbose")
      result[:status].success?.should be_true
      (/Failed/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_rolling_invalid_version/cnf-testsuite.yml deploy_with_chart=false")
    end
  end

  it "'rolling_downgrade' should pass when valid version is given", tags: ["rolling_downgrade"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      retry_limit = 5 
      retries = 1
      until (/Passed/ =~ result[:output]) || retries > retry_limit
        Log.info { "rolling_downgrade retry: #{retries}" }
        sleep 1.0
        result = ShellCmd.run_testsuite("rolling_downgrade verbose")
        retries = retries + 1
      end
      Log.info { result[:output] }
      result[:status].success?.should be_true
      (/Passed/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml")
    end
  end

  it "'rolling_downgrade' should fail when invalid version is given", tags: ["rolling_downgrade"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_rolling_invalid_version/cnf-testsuite.yml deploy_with_chart=false")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("rolling_downgrade verbose")
      result[:status].success?.should be_true
      (/Failed/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_rolling_invalid_version/cnf-testsuite.yml deploy_with_chart=false")
    end
  end

  it "'rolling_version_change' should pass when valid version is given", tags: ["rolling_version_change"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("rolling_version_change verbose")
      result[:status].success?.should be_true
      (/Passed/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml")
    end
  end

  it "'rolling_version_change' should fail when invalid version is given", tags: ["rolling_version_change"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_rolling_invalid_version/cnf-testsuite.yml deploy_with_chart=false")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("rolling_version_change verbose")
      result[:status].success?.should be_true
      (/Failed/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_rolling_invalid_version/cnf-testsuite.yml deploy_with_chart=false")
    end
  end

  it "'rollback' should pass ", tags: ["rollback"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("rollback verbose")
      result[:status].success?.should be_true
      (/Passed/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_rolling/cnf-testsuite.yml")
    end
  end

  # TODO: figure out failing test for rollback

  it "'nodeport_not_used' should fail when a node port is being used", tags: ["nodeport_not_used"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample_nodeport deploy_with_chart=false")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("nodeport_not_used verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(NodePort is being used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_nodeport deploy_with_chart=false")
    end
  end

  it "'nodeport_not_used' should pass when a node port is not being used", tags: ["nodeport_not_used"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("nodeport_not_used verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(NodePort is not used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml")
    end
  end

  it "'hostport_not_used' should fail when a node port is being used", tags: ["hostport_not_used"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample_hostport deploy_with_chart=false")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("hostport_not_used verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(HostPort is being used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_hostport deploy_with_chart=false")
    end
  end

  it "'hostport_not_used' should pass when a node port is not being used", tags: ["hostport_not_used"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("hostport_not_used verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(HostPort is not used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml")
    end
  end

  it "'ip_addresses' should pass when no uncommented ip addresses are found in helm chart source", tags: ["ip_addresses"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf-source/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("ip_addresses verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(No IP addresses found)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("sample_coredns_source_cleanup verbose")
    end
  end

  it "'hardcoded_ip_addresses_in_k8s_runtime_configuration' should fail when a hardcoded ip is found in the K8s configuration", tags: ["ip_addresses"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample_coredns_hardcoded_ips deploy_with_chart=false")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("hardcoded_ip_addresses_in_k8s_runtime_configuration verbose", cmd_prefix: "LOG_LEVEL=info")
      result[:status].success?.should be_true
      (/(FAILED).*(Hard-coded IP addresses found in the runtime K8s configuration)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_coredns_hardcoded_ips deploy_with_chart=false")
    end
  end

  it "'hardcoded_ip_addresses_in_k8s_runtime_configuration' should pass when no ip addresses are found in the K8s configuration", tags: ["ip_addresses"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("hardcoded_ip_addresses_in_k8s_runtime_configuration verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(No hard-coded IP addresses found in the runtime K8s configuration)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml")
    end
  end

  it "'secrets_used' should pass when secrets are provided as volumes and used by a container", tags: ["secrets"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_secret_volume/cnf-testsuite.yml verbose")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("secrets_used verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(Secrets defined and used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_secret_volume verbose")
    end
  end

  it "'secrets_used' should be skipped when secrets are provided as volumes and not mounted by a container", tags: ["secrets"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_unmounted_secret_volume/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("secrets_used verbose")
      result[:status].success?.should be_true
      (/(SKIPPED).*(Secrets not used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_unmounted_secret_volume verbose")
    end
  end

  it "'secrets_used' should pass when secrets are provided as environment variables and used by a container", tags: ["secrets"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_secret_env/cnf-testsuite.yml verbose")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("secrets_used verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(Secrets defined and used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_secret_env verbose")
    end
  end

  it "'secrets_used' should skip when secrets are not referenced as environment variables by a container", tags: ["secrets"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_secret_env_no_ref/cnf-testsuite.yml wait_count=2 verbose")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("secrets_used verbose")
      result[:status].success?.should be_true
      (/(SKIPPED).*(Secrets not used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_secret_env verbose")
    end
  end

  it "'secrets_used' should be skipped when no secret volumes are mounted or no container secrets are provided (secrets ignored)`", tags: ["secrets"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("secrets_used verbose")
      result[:status].success?.should be_true
      (/(SKIPPED).*(Secrets not used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_coredns verbose")
    end
  end

  it "'immutable_configmap' fail with some mutable configmaps in container env or volume mount", tags: ["immutable_configmap"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/ndn-mutable-configmap deploy_with_chart=false")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("immutable_configmap verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(Found mutable configmap)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/ndn-mutable-configmap deploy_with_chart=false")
    end
  end

  it "'immutable_configmap' pass with all immutable configmaps in container env or volume mounts", tags: ["immutable_configmap"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/ndn-immutable-configmap deploy_with_chart=false")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("immutable_configmap verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(All volume or container mounted configmaps immutable)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/ndn-immutable-configmap deploy_with_chart=false")
    end
  end

  it "'require_labels' should fail if a cnf does not have the app.kubernetes.io/name label", tags: ["require_labels"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_nonroot/cnf-testsuite.yml")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("require_labels verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(Pods should have the app.kubernetes.io\/name label)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_nonroot/cnf-testsuite.yml")
    end
  end

  it "'require_labels' should pass if a cnf has the app.kubernetes.io/name label", tags: ["require_labels"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("require_labels verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(Pods have the app.kubernetes.io\/name label)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml")
    end
  end

  it "'default_namespace' should fail if a cnf creates resources in the default namespace", tags: ["default_namespace"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_coredns_default_namespace")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("default_namespace verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(Resources are created in the default namespace)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_coredns_default_namespace")
      KubectlClient::Utils.wait_for_terminations()
    end
  end

  it "'default_namespace' should pass if a cnf does not create resources in the default namespace", tags: ["default_namespace"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_latest_tag")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("default_namespace verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(default namespace is not being used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_latest_tag")
      KubectlClient::Utils.wait_for_terminations()
    end
  end

  it "'latest_tag' should fail if a cnf has containers that use images with the latest tag", tags: ["latest_tag"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_latest_tag")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("latest_tag verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(Container images are using the latest tag)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_latest_tag")
    end
  end

  it "'latest_tag' should pass if a cnf does not have containers that use images with the latest tag", tags: ["latest_tag"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_nonroot")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("latest_tag verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(Container images are not using the latest tag)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_nonroot")
    end
  end

  it "'latest_tag' should require a cnf be installed to run", tags: ["latest_tag"] do
    begin
      # NOTE: Purposefully not installing a CNF to test
      result = ShellCmd.run_testsuite("latest_tag verbose")
      result[:status].success?.should be_false
      (/You must install a CNF first./ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_nonroot")
    end
  end
end
