require "./../spec_helper"
require "colorize"
require "./../../src/tasks/utils/utils.cr"

describe "Observability" do

  it "'kube_state_metrics' should return some json", tags: "platform:kube_state_metrics" do
      response_s = `./cnf-conformance platform:kube_state_metrics poc`
      LOGGING.info response_s
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for kube state metrics){1}/ =~ response_s).should_not be_nil
  end

  it "'node_exporter' should detect the named release of the installed node_exporter", tags: "platform:node_exporter" do
      response_s = `./cnf-conformance platform:node_exporter poc`
      LOGGING.info response_s
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for the node exporter){1}/ =~ response_s).should_not be_nil
  end

  it "'prometheus_adapter' should detect the named release of the installed prometheus_adapter", tags: "platform:prometheus_adapter" do
      response_s = `./cnf-conformance platform:prometheus_adapter poc`
      LOGGING.info response_s
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for the prometheus adapter){1}/ =~ response_s).should_not be_nil
  end

  it "'metrics_server' should detect the named release of the installed metrics_server", tags: "platform:metrics_server" do
      response_s = `./cnf-conformance platform:metrics_server poc`
      LOGGING.info response_s
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for the metrics server){1}/ =~ response_s).should_not be_nil
  end


end

