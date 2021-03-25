require "./../spec_helper"
require "colorize"
require "./../../src/tasks/utils/utils.cr"
require "./../../src/tasks/utils/kubectl_client.cr"

describe "Observability" do
  before_all do
    begin
      current_dir = FileUtils.pwd 
      LOGGING.info current_dir
      # helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
      LOGGING.info "helm path: #{CNFSingleton.helm}"
      helm = CNFSingleton.helm
      LOGGING.info "Installing kube_state_metrics" 
      resp = `#{helm} install kube-state-metrics stable/kube-state-metrics`
      LOGGING.info resp
      KubectlClient::Get.wait_for_install("kube-state-metrics")

			LOGGING.info "Installing prometheus-node-exporter" 
			resp = `#{helm} install node-exporter stable/prometheus-node-exporter`
			LOGGING.info resp

			LOGGING.info "Installing prometheus-adapter" 
			resp = `#{helm} install prometheus-adapter stable/prometheus-adapter`
			LOGGING.info resp
			KubectlClient::Get.wait_for_install("prometheus-adapter")

			LOGGING.info "Installing metrics_server" 
			resp = `kubectl create -f spec/fixtures/metrics-server.yaml`
			LOGGING.info resp
			KubectlClient::Get.wait_for_install(deployment_name: "metrics-server", namespace:"kube-system")
		rescue ex
			LOGGING.error ex.message
			ex.backtrace.each do |x| 
				LOGGING.error x
			end 
		end 
  end

  after_all do
    current_dir = FileUtils.pwd 
    LOGGING.info current_dir
    # helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    LOGGING.info "helm path: #{CNFSingleton.helm}"
    helm = CNFSingleton.helm
    resp = `#{helm} delete kube-state-metrics`
    LOGGING.info resp
    $?.success?.should be_true
    resp = `#{helm} delete node-exporter`
    LOGGING.info resp
    $?.success?.should be_true
    resp = `#{helm} delete prometheus-adapter`
    LOGGING.info resp
    $?.success?.should be_true
    resp = `kubectl delete -f spec/fixtures/metrics-server.yaml`
    LOGGING.info resp
    $?.success?.should be_true
  end

  it "'kube_state_metrics' should return some json", tags: ["platform:kube_state_metrics"] do
      response_s = `./cnf-conformance platform:kube_state_metrics poc`
      LOGGING.info response_s
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for kube state metrics){1}/ =~ response_s).should_not be_nil
  end

  it "'node_exporter' should detect the named release of the installed node_exporter", tags: ["platform:node_exporter"] do
      pod_ready = ""
      pod_ready_timeout = 45
      until (pod_ready == "true" || pod_ready_timeout == 0)
        pod_ready = KubectlClient::Get.pod_status("node-exporter-prometheus").split(",")[2]
        puts "Pod Ready Status: #{pod_ready}"
        sleep 1
        pod_ready_timeout = pod_ready_timeout - 1
      end
      response_s = `./cnf-conformance platform:node_exporter poc`
      LOGGING.info response_s
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for the node exporter){1}/ =~ response_s).should_not be_nil
  end

  it "'prometheus_adapter' should detect the named release of the installed prometheus_adapter", tags: ["platform:prometheus_adapter"] do
      response_s = `./cnf-conformance platform:prometheus_adapter poc`
      LOGGING.info response_s
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for the prometheus adapter){1}/ =~ response_s).should_not be_nil
  end

  it "'metrics_server' should detect the named release of the installed metrics_server", tags: ["platform:metrics_server"] do
      response_s = `./cnf-conformance platform:metrics_server poc`
      LOGGING.info response_s
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for the metrics server){1}/ =~ response_s).should_not be_nil
  end
end

