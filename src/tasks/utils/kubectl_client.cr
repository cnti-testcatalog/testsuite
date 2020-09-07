require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"

module KubectlClient 
  # https://www.capitalone.com/tech/cloud/container-runtime/
  OCI_RUNTIME_REGEX = /containerd|docker|runc|railcar|crun|rkt|gviso|nabla|runv|clearcontainers|kata|cri-o/i
  module Get 
    def self.nodes : JSON::Any
      resp = `kubectl get nodes -o json`
      LOGGING.info "kubectl get nodes: #{resp}"
      JSON.parse(resp)
    end
    def self.container_runtime
      nodes["items"][0]["status"]["nodeInfo"]["containerRuntimeVersion"].as_s
    end
    def self.container_runtimes
      runtimes = nodes["items"].as_a.map do |x|
        x["status"]["nodeInfo"]["containerRuntimeVersion"].as_s
      end
      LOGGING.info "runtimes: #{runtimes}"
      runtimes.uniq
    end
  end
end
