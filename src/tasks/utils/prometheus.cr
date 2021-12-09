module Prometheus

  def self.open_metric_validator(url)
    Log.info { "ClusterTools open_metric_validator" }
    cli = %(/bin/bash -c "curl #{url} | openmetricsvalidator")
    resp = ClusterTools.exec(cli)
    Log.info { "metrics resp: #{resp}"}
    resp
  end

  class OpenMetricConfigMapTemplate
    def initialize(@name : String, 
                   @open_metrics_validated : Bool,
                   @open_metrics_response : String, 
                   @immutable : Bool)
    end

    ECR.def_to_s("src/templates/open_metric_configmap_template.yml.ecr")
  end
end
