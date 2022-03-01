require "./../spec_helper"
require "colorize"
require "./../../src/tasks/utils/utils.cr"
require "kubectl_client"

describe "Platform Observability" do
  before_all do
    `./cnf-testsuite setup`
    $?.success?.should be_true
  end

  it "'kube_state_metrics' should return some json", tags: ["platform:observability"] do

      LOGGING.info "Installing kube_state_metrics" 
      helm = BinarySingleton.helm
      resp = `#{helm} install kube-state-metrics stable/kube-state-metrics`
      LOGGING.info resp
      KubectlClient::Get.wait_for_install("kube-state-metrics")

      response_s = `./cnf-testsuite platform:kube_state_metrics poc`
      LOGGING.info response_s
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for kube state metrics){1}/ =~ response_s).should_not be_nil
  ensure
      resp = `#{helm} delete kube-state-metrics`
      LOGGING.info resp
      $?.success?.should be_true
  end

  it "'node_exporter' should detect the named release of the installed node_exporter", tags: ["platform:observability"] do

		  LOGGING.info "Installing prometheus-node-exporter" 
      helm = BinarySingleton.helm
		  resp = `#{helm} install node-exporter stable/prometheus-node-exporter`
		  LOGGING.info resp

      pod_ready = ""
      pod_ready_timeout = 45
      until (pod_ready == "true" || pod_ready_timeout == 0)
        pod_ready = KubectlClient::Get.pod_status("node-exporter-prometheus").split(",")[2]
        Log.info { "Pod Ready Status: #{pod_ready}" }
        sleep 1
        pod_ready_timeout = pod_ready_timeout - 1
      end
      response_s = `./cnf-testsuite platform:node_exporter poc`
      LOGGING.info response_s
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for the node exporter){1}/ =~ response_s).should_not be_nil
  ensure
      resp = `#{helm} delete node-exporter`
      LOGGING.info resp
      $?.success?.should be_true
  end

  it "'prometheus_adapter' should detect the named release of the installed prometheus_adapter", tags: ["platform:observability"] do
    Log.info { "Installing prometheus-adapter" }
    helm = BinarySingleton.helm
    begin
      result = Helm.install("prometheus-adapter stable/prometheus-adapter")
      Log.info { "Prometheus installed" }
    rescue e : Helm::CannotReuseReleaseNameError
      Log.info { "Prometheus already installed" }
    end
    KubectlClient::Get.wait_for_install("prometheus-adapter")
    response_s = `./cnf-testsuite platform:prometheus_adapter poc`
    LOGGING.info response_s
    (/(PASSED){1}.*(Your platform is using the){1}.*(release for the prometheus adapter){1}/ =~ response_s).should_not be_nil
  ensure
    resp = Helm.uninstall("prometheus-adapter")
  end

  it "'metrics_server' should detect the named release of the installed metrics_server", tags: ["platform:observability"] do
		  LOGGING.info "Installing metrics_server" 
		  resp = `kubectl create -f spec/fixtures/metrics-server.yaml`
		  LOGGING.info resp
		  KubectlClient::Get.wait_for_install(deployment_name: "metrics-server", namespace:"kube-system")

      response_s = `./cnf-testsuite platform:metrics_server poc`
      LOGGING.info response_s
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for the metrics server){1}/ =~ response_s).should_not be_nil
  ensure
      resp = `kubectl delete -f spec/fixtures/metrics-server.yaml`
      LOGGING.info resp
      $?.success?.should be_true
  end
end

