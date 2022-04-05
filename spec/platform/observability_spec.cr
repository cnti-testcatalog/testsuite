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
      if check_containerd
        (/(PASSED){1}.*(Your platform is using the){1}.*(release for the node exporter){1}/ =~ response_s).should_not be_nil
      else
        (/skipping node_exporter: This test only supports the Containerd Runtime./ =~ response_s).should_not be_nil
      end
  ensure
      resp = `#{helm} delete node-exporter`
      LOGGING.info resp
      $?.success?.should be_true
  end

  it "'prometheus_adapter' should detect the named release of the installed prometheus_adapter", tags: ["platform:observability"] do
    Log.info { "Installing prometheus-adapter" }
    helm = BinarySingleton.helm
    begin
      Helm.helm_repo_add("prometheus-community","https://prometheus-community.github.io/helm-charts")
      result = Helm.install("prometheus-adapter prometheus-community/prometheus-adapter")
      Log.info { "Prometheus installed" }
    rescue e : Helm::CannotReuseReleaseNameError
      Log.info { "Prometheus already installed" }
    end
    KubectlClient::Get.wait_for_install("prometheus-adapter")

    response_s = `./cnf-testsuite platform:prometheus_adapter poc`
    Log.info { response_s }
    (/(PASSED){1}.*(Your platform is using the){1}.*(release for the prometheus adapter){1}/ =~ response_s).should_not be_nil
  ensure
    resp = Helm.uninstall("prometheus-adapter")
  end

  it "'metrics_server' should detect the named release of the installed metrics_server", tags: ["platform:observability"] do
    Log.info { "Installing metrics-server" }
    helm = BinarySingleton.helm
    begin
      Helm.helm_repo_add("metrics-server","https://kubernetes-sigs.github.io/metrics-server/")
      result = Helm.install("--set image.repository=docker.io/bitnami/metrics-server --set image.tag=0.6.1 --set args={--kubelet-insecure-tls} metrics-server metrics-server/metrics-server")
      Log.info { "Metrics Server installed" }
    rescue e : Helm::CannotReuseReleaseNameError
      Log.info { "Metrics Server already installed" }
    end
		  Log.info { result } 
		  KubectlClient::Get.wait_for_install(deployment_name: "metrics-server")
      response_s = `./cnf-testsuite platform:metrics_server poc`
      LOGGING.info response_s
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for the metrics server){1}/ =~ response_s).should_not be_nil
  ensure
      resp = Helm.uninstall("metrics-server")
      LOGGING.info resp
      $?.success?.should be_true
  end
end

