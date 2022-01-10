require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/jaeger_setup.cr"

describe "Observability" do
  it "'log_output' should pass with a cnf that outputs logs to stdout", tags: ["observability"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      response_s = `./cnf-testsuite log_output verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Resources output logs to stdout and stderr/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
    end
  end

  it "'log_output' should fail with a cnf that does not output logs to stdout", tags: ["observability"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_no_logs/cnf-testsuite.yml`
      response_s = `./cnf-testsuite log_output verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Resources do not output logs to stdout and stderr/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample_no_logs/cnf-testsuite.yml`
    end
  end

  it "'prometheus_traffic' should pass if there is prometheus traffic", tags: ["observability"] do

      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-prom-pod-discovery/cnf-testsuite.yml`
      LOGGING.info `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
      LOGGING.info "Installing prometheus server" 
      helm = BinarySingleton.helm
      # resp = `#{helm} install prometheus prometheus-community/prometheus`
      resp = `#{helm} install --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false prometheus prometheus-community/prometheus`
      LOGGING.info resp
      KubectlClient::Get.wait_for_install("prometheus-server")
      LOGGING.info `kubectl describe deployment prometheus-server`
      #todo logging on prometheus pod

      response_s = `./cnf-testsuite prometheus_traffic`
      LOGGING.info response_s
      (/PASSED: Your cnf is sending prometheus traffic/ =~ response_s).should_not be_nil
  ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-prom-pod-discovery/cnf-testsuite.yml`
      resp = `#{helm} delete prometheus`
      LOGGING.info resp
      $?.success?.should be_true
  end

  it "'prometheus_traffic' should skip if there is no prometheus installed", tags: ["observability"] do

      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      helm = BinarySingleton.helm
      resp = `#{helm} delete prometheus`
      LOGGING.info resp

      response_s = `./cnf-testsuite prometheus_traffic`
      LOGGING.info response_s
      (/SKIPPED: Prometheus server not found/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
  end

  it "'prometheus_traffic' should fail if the cnf is not registered with prometheus", tags: ["observability"] do

      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      LOGGING.info "Installing prometheus server" 
      helm = BinarySingleton.helm
      LOGGING.info `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
      # resp = `#{helm} install prometheus prometheus-community/prometheus`
      resp = `#{helm} install --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false prometheus prometheus-community/prometheus`
      LOGGING.info resp
      KubectlClient::Get.wait_for_install("prometheus-server")
      LOGGING.info `kubectl describe deployment prometheus-server`
      #todo logging on prometheus pod

      response_s = `./cnf-testsuite prometheus_traffic`
      LOGGING.info response_s
      (/FAILED: Your cnf is not sending prometheus traffic/ =~ response_s).should_not be_nil
  ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      resp = `#{helm} delete prometheus`
      LOGGING.info resp
      $?.success?.should be_true
  end
end

it "'open_metrics' should fail if there is not a valid open metrics response from the cnf", tags: ["observability"] do

  LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-prom-pod-discovery/cnf-testsuite.yml`
  LOGGING.info `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
  LOGGING.info "Installing prometheus server" 
  helm = BinarySingleton.helm
  # resp = `#{helm} install prometheus prometheus-community/prometheus`
  resp = `#{helm} install --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false prometheus prometheus-community/prometheus`
  LOGGING.info resp
  KubectlClient::Get.wait_for_install("prometheus-server")
  LOGGING.info `kubectl describe deployment prometheus-server`
  #todo logging on prometheus pod

  response_s = `./cnf-testsuite open_metrics`
  LOGGING.info response_s
  (/FAILED: Your cnf's metrics traffic is not Open Metrics compatible/ =~ response_s).should_not be_nil
ensure
  LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-prom-pod-discovery/cnf-testsuite.yml`
  resp = `#{helm} delete prometheus`
  LOGGING.info resp
  $?.success?.should be_true
end

it "'open_metrics' should pass if there is a valid open metrics response from the cnf", tags: ["observability"] do

  LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-openmetrics/cnf-testsuite.yml`
  LOGGING.info `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
  LOGGING.info "Installing prometheus server" 
  helm = BinarySingleton.helm
  # resp = `#{helm} install prometheus prometheus-community/prometheus`
  resp = `#{helm} install --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false prometheus prometheus-community/prometheus`
  LOGGING.info resp
  KubectlClient::Get.wait_for_install("prometheus-server")
  LOGGING.info `kubectl describe deployment prometheus-server`
  #todo logging on prometheus pod

  response_s = `./cnf-testsuite open_metrics`
  LOGGING.info response_s
  (/PASSED: Your cnf's metrics traffic is Open Metrics compatible/ =~ response_s).should_not be_nil
ensure
  LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-openmetrics/cnf-testsuite.yml`
  resp = `#{helm} delete prometheus`
  LOGGING.info resp
  $?.success?.should be_true
end

it "'routed_logs' should pass if cnfs logs are captured", tags: ["observability"] do

  LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
  resp = `./cnf-testsuite install_fluentd`
  LOGGING.info resp
  response_s = `./cnf-testsuite routed_logs`
  LOGGING.info response_s
  (/PASSED: Your cnf's logs are being captured/ =~ response_s).should_not be_nil
ensure
  LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
  resp = `./cnf-testsuite uninstall_fluentd`
  LOGGING.info resp
  $?.success?.should be_true
end

it "'routed_logs' should fail if cnfs logs are not captured", tags: ["observability"] do

  LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
  # resp = `./cnf-testsuite install_fluentd`
  Log.info {"Installing FluentD daemonset "}
  Helm.helm_repo_add("fluent","https://fluent.github.io/helm-charts")
  #todo  #helm install --values ./override.yml fluentd ./fluentd
  Helm.install("--values ./spec/fixtures/fluentd-values-bad.yml fluentd fluent/fluentd")
  KubectlClient::Get.resource_wait_for_install("Daemonset", "fluentd")

  response_s = `./cnf-testsuite routed_logs`
  LOGGING.info response_s
  (/FAILED: Your cnf's logs are not being captured/ =~ response_s).should_not be_nil
ensure
  LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
  resp = `./cnf-testsuite uninstall_fluentd`
  LOGGING.info resp
  $?.success?.should be_true
end

it "'tracing' should fail if tracing is not used", tags: ["observability_jager"] do
  Log.info {"Installing Jaeger "}
  JaegerManager.install
  
  LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
  response_s = `./cnf-testsuite tracing`
  LOGGING.info response_s
  (/FAILED: Tracing not used/ =~ response_s).should_not be_nil
ensure
  LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
  JaegerManager.uninstall
end

it "'tracing' should pass if tracing is used", tags: ["observability_jager"] do
  Log.info {"Installing Jaeger "}
  JaegerManager.install

  LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-tracing/cnf-testsuite.yml`
  response_s = `./cnf-testsuite tracing`
  LOGGING.info response_s
  (/PASSED: Tracing used/ =~ response_s).should_not be_nil
ensure
  LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-tracing/cnf-testsuite.yml`
  JaegerManager.uninstall
end

