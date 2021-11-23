module Prometheus
  class OpenMetricConfigMapTemplate
    def initialize(@release_name : String, @open_metrics_validated : Bool, @immutable : Bool)
    end

    ECR.def_to_s("src/templates/open_metric_configmap_template.yml.ecr")
  end
end
