require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"

module Falco

  FALCO_POD_LABEL_KEY="app"
  FALCO_POD_LABEL_VALUE="falco"
  def self.find_root_pod(pod_name : String)
    Log.info { "Falco.find_root_pod: #{pod_name}" }

    # get all resource_ymls
    node_pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(node_pods, FALCO_POD_LABEL_KEY, FALCO_POD_LABEL_VALUE)
    matched = false
    pods.map do |pod|
      falco_pod_name = pod.dig("metadata", "name").as_s
      resp = KubectlClient.logs(falco_pod_name, namespace: TESTSUITE_NAMESPACE)
      output = resp[:output]
      match = output.to_s.match(/.*A container with a root proccess was detected.*\(k8s_pod=#{pod_name}\).*/)
      if match
        Log.info { "Falco Root Pod Data: #{match[0]}" }
        matched = true
        # todo continue to inspect all nodes and show which node caused the failer
        break
      end
    end
    matched
  end
end
