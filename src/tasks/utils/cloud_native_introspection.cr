
require "colorize"
require "kubectl_client"

module CloudNativeIntrospection
  PROMETHEUS_PROCESS = "prometheus"
  STATE_METRICS_PROCESS = "kube-state-metrics"
  METRICS_SERVER = "metrics-server"
end
