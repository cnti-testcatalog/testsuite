require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"

module KubectlClient 
  # https://www.capitalone.com/tech/cloud/container-runtime/
  OCI_RUNTIME_REGEX = /containerd|docker|runc|railcar|crun|rkt|gviso|nabla|runv|clearcontainers|kata|cri-o/i
  module Get 
    def self.nodes : JSON::Any
      # TODO should this be all namespaces?
      resp = `kubectl get nodes -o json`
      LOGGING.debug "kubectl get nodes: #{resp}"
      JSON.parse(resp)
    end

    def self.deployment(deployment_name) : JSON::Any
      resp = `kubectl get deployment nginx-webapp -o json`
      LOGGING.debug "kubectl get deployment: #{resp}"
      JSON.parse(resp)
    end

    def self.deployment_containers(deployment_name) : JSON::Any 
      resp = deployment(deployment_name).dig?("spec", "template", "spec", "containers")
      LOGGING.debug "kubectl get deployment containers: #{resp}"
      if resp 
        resp
      else
        JSON.parse(%({}))
      end
    end

    def self.worker_nodes : Array(String)
      resp = `kubectl get nodes --selector='!node-role.kubernetes.io/master' -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ "\\n"}}{{end}}{{end}}'`
      LOGGING.debug "kubectl get nodes: #{resp}"
      resp.split("\n")
    end
    def self.schedulable_nodes : Array(String)
      resp = `kubectl get nodes -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ "\\n"}}{{end}}{{end}}'`
      LOGGING.debug "kubectl get nodes: #{resp}"
      resp.split("\n")
    end
    def self.pv : JSON::Any
      # TODO should this be all namespaces?
      resp = `kubectl get pv -o json`
      LOGGING.debug "kubectl get pv: #{resp}"
      JSON.parse(resp)
    end
    def self.pv_items_by_claim_name(claim_name)
      items = pv["items"].as_a.map do |x|
        begin
          if x["spec"]["claimRef"]["name"] == claim_name
            x
          else
            nil
          end
        rescue ex
          LOGGING.info ex.message 
          nil
        end
      end.compact
      LOGGING.debug "pv items : #{items}"
      items 
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
    def self.pods : JSON::Any
      resp = `kubectl get pods --all-namespaces -o json`
      LOGGING.debug "kubectl get pods: #{resp}"
      JSON.parse(resp)
    end
    def self.all_pod_statuses
      statuses = pods["items"].as_a.map do |x|
        x["status"]
      end
      LOGGING.debug "pod statuses: #{statuses}"
      statuses
    end
    def self.all_pod_container_statuses
      statuses = all_pod_statuses.map do |x|
        x["containerStatuses"].as_a
      end
      # LOGGING.info "pod container statuses: #{statuses}"
      statuses
    end
    def self.all_container_repo_digests
      imageids = all_pod_container_statuses.reduce([] of String) do |acc, x|
        # acc << "hi"
        acc | x.map{|i| i["imageID"].as_s}
      end
      LOGGING.debug "pod container image ids: #{imageids}"
      imageids
    end
  end
end
