require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"

module KubectlClient 
  # https://www.capitalone.com/tech/cloud/container-runtime/
  OCI_RUNTIME_REGEX = /containerd|docker|runc|railcar|crun|rkt|gviso|nabla|runv|clearcontainers|kata|cri-o/i
  module Rollout
    def self.status(deployment_name, timeout="30s")
      rollout = `kubectl rollout status deployment/#{deployment_name} --timeout=#{timeout}`
      rollout_status = $?.success?
      LOGGING.debug "#{rollout}"
      LOGGING.debug "rollout? #{rollout_status}"
      $?.success?
    end
  end
  module Set
    def self.image(deployment_name, container_name, image_name, version_tag=nil)
      if version_tag
        # use --record to have history
        resp  = `kubectl set image deployment/#{deployment_name} #{container_name}=#{image_name}:#{version_tag} --record`
      else
        resp  = `kubectl set image deployment/#{deployment_name} #{container_name}=#{image_name} --record`
      end
      LOGGING.debug "set image: #{resp}" 
      $?.success?
    end
  end
  module Get 
    def self.nodes : JSON::Any
      # TODO should this be all namespaces?
      resp = `kubectl get nodes -o json`
      LOGGING.debug "kubectl get nodes: #{resp}"
      JSON.parse(resp)
    end

    def self.deployment(deployment_name) : JSON::Any
      resp = `kubectl get deployment #{deployment_name} -o json`
      LOGGING.debug "kubectl get deployment: #{resp}"
      JSON.parse(resp)
    end

    def self.save_manifest(deployment_name, output_file) 
      resp = `kubectl get deployment #{deployment_name} -o yaml  > #{output_file}`
      LOGGING.debug "kubectl save_manifest: #{resp}"
      $?.success?
    end

    def self.deployments : JSON::Any
      resp = `kubectl get deployments -o json`
      LOGGING.debug "kubectl get deployment: #{resp}"
      JSON.parse(resp)
    end

    def self.deployment_containers(deployment_name) : JSON::Any 
      LOGGING.debug "kubectl get deployment containers deployment_name: #{deployment_name}"
      resp = deployment(deployment_name).dig?("spec", "template", "spec", "containers")
      LOGGING.debug "kubectl get deployment containers: #{resp}"
      if resp 
        resp
      else
        JSON.parse(%({}))
      end
    end

    def self.container_image_tags(deployment_containers) : Array(NamedTuple(image: String, 
                                                                            tag: String | Nil))
      image_tags = deployment_containers.as_a.map do |container|
        LOGGING.debug "container (should have image and tag): #{container}"
        {image: container.as_h["image"].as_s.split(":")[0],
         #TODO an image may not have a tag
         tag: container.as_h["image"].as_s.split(":")[1]?}
      end
      LOGGING.debug "image_tags: #{image_tags}"
      image_tags
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
    def self.pods(all_namespaces=true) : JSON::Any
      option = all_namespaces ? "--all-namespaces" : ""
      resp = `kubectl get pods #{option} -o json`
      LOGGING.debug "kubectl get pods: #{resp}"
      JSON.parse(resp)
    end

    # *pod_exists* returns true if a pod containing *pod_name* exists, regardless of status.
    # If *check_ready* is set to true, *pod_exists* validates that the pod exists and 
    # has a ready status of true
    def self.pod_exists?(pod_name, check_ready=false, all_namespaces=false) 
      LOGGING.debug "pod_exists? pod_name: #{pod_name}"
      exists = pods(all_namespaces)["items"].as_a.any? do |x|
        (name_comparison = x["metadata"]["name"].as_s? =~ /#{pod_name}/
        (x["metadata"]["name"].as_s? =~ /#{pod_name}/) || 
          (x["metadata"]["generateName"]? && x["metadata"]["generateName"].as_s? =~ /#{pod_name}/)) &&
        (check_ready && (x["status"]["conditions"].as_a.find{|x| x["type"].as_s? == "Ready"} && x["status"].as_s? == "True") || check_ready==false)
      end
      LOGGING.debug "pod exists: #{exists}"
      exists 
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
