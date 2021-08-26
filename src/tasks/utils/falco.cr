require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"

module Falco

  FALCO_POD_LABEL_KEY="app"
  FALCO_POD_LABEL_VALUE="falco"
  def self.find_root_pod(pod_name)
    LOGGING.info "Falco.find_root_pod: #{pod_name}"

    # get all resource_ymls
    node_pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(node_pods, FALCO_POD_LABEL_KEY, FALCO_POD_LABEL_VALUE)
    matched = false
    pods.map do |pod|
      falco_pod_name = pod.dig("metadata", "name")
      resp = KubectlClient.logs(falco_pod_name)
      output = resp[:output]
      match = output.to_s.match(/.*root.*\(k8s_pod=#{pod_name}\)/) 
      if match
        LOGGING.info "Falco Root Pod Data: #{match[0]}"
        matched = true
        # todo continue to inspect all nodes and show which node caused the failer
        break
      end
    end
    matched
  end
end
