module Prometheus
  class OpenMetricConfigMapTemplate
    def initialize(@name : String, 
                   @open_metrics_validated : Bool,
                   @open_metrics_response : String, 
                   @immutable : Bool)
    end

    ECR.def_to_s("src/templates/open_metric_configmap_template.yml.ecr")
  end
end
