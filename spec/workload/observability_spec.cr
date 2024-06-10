require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/fluent_manager.cr"
require "../../src/tasks/jaeger_setup.cr"

describe "Observability" do
  before_all do
    result = ShellCmd.run_testsuite("setup")
    result[:status].success?.should be_true
  end

  it "'log_output' should pass with a cnf that outputs logs to stdout", tags: ["observability"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
      result = ShellCmd.run_testsuite("log_output verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(Resources output logs to stdout and stderr)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
    end
  end

  it "'log_output' should fail with a cnf that does not output logs to stdout", tags: ["observability"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample_no_logs/cnf-testsuite.yml")
      result = ShellCmd.run_testsuite("log_output verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(Resources do not output logs to stdout and stderr)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample_no_logs/cnf-testsuite.yml")
    end
  end

  it "'prometheus_traffic' should pass if there is prometheus traffic", tags: ["observability"] do
    ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-prom-pod-discovery/cnf-testsuite.yml")
    helm = Helm::BinarySingleton.helm

    Log.info { "Add prometheus helm repo" }
    ShellCmd.run("#{helm} repo add prometheus-community https://prometheus-community.github.io/helm-charts", "helm_repo_add_prometheus", force_output: true)

    Log.info { "Installing prometheus server" }
    install_cmd = "#{helm} install --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false prometheus prometheus-community/prometheus"
    ShellCmd.run(install_cmd, "helm_install_prometheus", force_output: true)

    KubectlClient::Get.wait_for_install("prometheus-server")
    ShellCmd.run("kubectl describe deployment prometheus-server", "k8s_describe_prometheus", force_output: true)

    test_result = ShellCmd.run_testsuite("prometheus_traffic")
    (/(PASSED).*(Your cnf is sending prometheus traffic)/ =~ test_result[:output]).should_not be_nil
  ensure
    ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-prom-pod-discovery/cnf-testsuite.yml")
    result = ShellCmd.run("#{helm} delete prometheus", "helm_delete_prometheus")
    result[:status].success?.should be_true
  end

  it "'prometheus_traffic' should skip if there is no prometheus installed", tags: ["observability"] do

      result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
      helm = Helm::BinarySingleton.helm
      result = ShellCmd.run("#{helm} delete prometheus", force_output: true)

      result = ShellCmd.run_testsuite("prometheus_traffic")
      (/(SKIPPED).*(Prometheus server not found)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
  end

  it "'prometheus_traffic' should fail if the cnf is not registered with prometheus", tags: ["observability"] do

      result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
      Log.info { "Installing prometheus server" }
      helm = Helm::BinarySingleton.helm
      result = ShellCmd.run("helm repo add prometheus-community https://prometheus-community.github.io/helm-charts", force_output: true)
      result = ShellCmd.run("#{helm} install --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false prometheus prometheus-community/prometheus", force_output: true)
      KubectlClient::Get.wait_for_install("prometheus-server")
      result = ShellCmd.run("kubectl describe deployment prometheus-server", force_output: true)
      #todo logging on prometheus pod

      result = ShellCmd.run_testsuite("prometheus_traffic")
      (/(FAILED).*(Your cnf is not sending prometheus traffic)/ =~ result[:output]).should_not be_nil
  ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
      result = ShellCmd.run("#{helm} delete prometheus", force_output: true)
      result[:status].success?.should be_true
  end

  it "'open_metrics' should fail if there is not a valid open metrics response from the cnf", tags: ["observability"] do
    result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-prom-pod-discovery/cnf-testsuite.yml")
    result = ShellCmd.run("helm repo add prometheus-community https://prometheus-community.github.io/helm-charts", force_output: true)
    Log.info { "Installing prometheus server" }
    helm = Helm::BinarySingleton.helm
    result = ShellCmd.run("#{helm} install --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false prometheus prometheus-community/prometheus", force_output: true)
    KubectlClient::Get.wait_for_install("prometheus-server")
    result = ShellCmd.run("kubectl describe deployment prometheus-server", force_output: true)
    #todo logging on prometheus pod

    result = ShellCmd.run_testsuite("open_metrics")
    (/(FAILED).*(Your cnf's metrics traffic is not OpenMetrics compatible)/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-prom-pod-discovery/cnf-testsuite.yml")
    result = ShellCmd.run("#{helm} delete prometheus", force_output: true)
    result[:status].success?.should be_true
  end

  it "'open_metrics' should pass if there is a valid open metrics response from the cnf", tags: ["observability"] do
    result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-openmetrics/cnf-testsuite.yml")
    result = ShellCmd.run("helm repo add prometheus-community https://prometheus-community.github.io/helm-charts", force_output: true)
    Log.info { "Installing prometheus server" }
    helm = Helm::BinarySingleton.helm
    result = ShellCmd.run("#{helm} install --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false prometheus prometheus-community/prometheus", force_output: true)
    KubectlClient::Get.wait_for_install("prometheus-server")
    result = ShellCmd.run("kubectl describe deployment prometheus-server", force_output: true)
    #todo logging on prometheus pod

    result = ShellCmd.run_testsuite("open_metrics")
    (/(PASSED).*(Your cnf's metrics traffic is OpenMetrics compatible)/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-openmetrics/cnf-testsuite.yml")
    result = ShellCmd.run("#{helm} delete prometheus", force_output: true)
    result[:status].success?.should be_true
  end

  it "'routed_logs' should pass if cnfs logs are captured by fluentd bitnami", tags: ["observability"] do
    result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
    result = ShellCmd.run_testsuite("install_fluentdbitnami")
    result = ShellCmd.run_testsuite("routed_logs")
    (/(PASSED).*(Your CNF's logs are being captured)/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
    result = ShellCmd.run_testsuite("uninstall_fluentdbitnami")
    result[:status].success?.should be_true
  end

  it "'routed_logs' should pass if cnfs logs are captured by fluentbit", tags: ["observability"] do
    result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-fluentbit")
    result = ShellCmd.run_testsuite("install_fluentbit")
    result = ShellCmd.run_testsuite("routed_logs")
    (/(PASSED).*(Your CNF's logs are being captured)/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-fluentbit")
    result = ShellCmd.run_testsuite("uninstall_fluentbit")
    result[:status].success?.should be_true
  end

  it "'routed_logs' should fail if cnfs logs are not captured", tags: ["observability"] do
  
    result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
    Helm.helm_repo_add("bitnami","https://charts.bitnami.com/bitnami")
    #todo  #helm install --values ./override.yml fluentd ./fluentd
    Helm.install("--values ./spec/fixtures/fluentd-values-bad.yml -n #{TESTSUITE_NAMESPACE} fluentd bitnami/fluentd")
    Log.info { "Installing FluentD daemonset" }
    KubectlClient::Get.resource_wait_for_install("Daemonset", "fluentd", namespace: TESTSUITE_NAMESPACE)

    result = ShellCmd.run_testsuite("routed_logs")
    (/(FAILED).*(Your CNF's logs are not being captured)/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
    result = ShellCmd.run_testsuite("uninstall_fluentd")
    result[:status].success?.should be_true
  end

  it "'tracing' should fail if tracing is not used", tags: ["observability_jaeger_fail"] do
    Log.info { "Installing Jaeger " }
    JaegerManager.install

    result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
    result = ShellCmd.run_testsuite("tracing")
    (/(FAILED).*(Tracing not used)/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
    JaegerManager.uninstall
    KubectlClient::Get.resource_wait_for_uninstall("Statefulset", "jaeger-cassandra")
    KubectlClient::Get.resource_wait_for_uninstall("Deployment", "jaeger-collector")
    KubectlClient::Get.resource_wait_for_uninstall("Deployment", "jaeger-query")
    KubectlClient::Get.resource_wait_for_uninstall("Daemonset", "jaeger-agent")
  end

  it "'tracing' should pass if tracing is used", tags: ["observability_jaeger_pass"] do
    Log.info { "Installing Jaeger " }
    JaegerManager.install

    result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-tracing/cnf-testsuite.yml")
    result = ShellCmd.run_testsuite("tracing")
    (/(PASSED).*(Tracing used)/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-tracing/cnf-testsuite.yml")
    JaegerManager.uninstall
    KubectlClient::Get.resource_wait_for_uninstall("Statefulset", "jaeger-cassandra")
    KubectlClient::Get.resource_wait_for_uninstall("Deployment", "jaeger-collector")
    KubectlClient::Get.resource_wait_for_uninstall("Deployment", "jaeger-query")
    KubectlClient::Get.resource_wait_for_uninstall("Daemonset", "jaeger-agent")
  end

end
