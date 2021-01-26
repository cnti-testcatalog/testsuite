require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"

module KubectlClient 
  WORKLOAD_RESOURCES = {deployment: "Deployment", 
                        service: "Service", 
                        pod: "Pod", 
                        replicaset: "ReplicaSet", 
                        statefulset: "StatefulSet", 
                        daemonset: "DaemonSet"}

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
    def self.resource_status(kind, resource_name, timeout="30s")
      rollout = `kubectl rollout status #{kind}/#{resource_name} --timeout=#{timeout}`
      rollout_status = $?.success?
      LOGGING.debug "#{rollout}"
      LOGGING.debug "rollout? #{rollout_status}"
      $?.success?
    end

    def self.undo(deployment_name)
      rollback = `kubectl rollout undo deployment/#{deployment_name}`
      rollback_status = $?.success?
      LOGGING.debug "#{rollback}"
      LOGGING.debug "rollback? #{rollback_status}"
      $?.success?
    end
  end
  module Set
    def self.image(deployment_name, container_name, image_name, version_tag=nil)
      #TODO check if image exists in repo? DockerClient::Get.image and image_by_tags
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
    def self.privileged_containers(namespace="--all-namespaces")
      privileged_response = `kubectl get pods #{namespace} -o jsonpath='{.items[*].spec.containers[?(@.securityContext.privileged==true)].name}'`
      # TODO parse this as json
      resp = privileged_response.to_s.split(" ").uniq
      LOGGING.debug "kubectl get privileged_containers: #{resp}"
      resp
    end

    def self.nodes : JSON::Any
      # TODO should this be all namespaces?
      resp = `kubectl get nodes -o json`
      LOGGING.debug "kubectl get nodes: #{resp}"
      JSON.parse(resp)
    end

    def self.deployment(deployment_name) : JSON::Any
      resp = `kubectl get deployment #{deployment_name} -o json`
      LOGGING.debug "kubectl get deployment: #{resp}"
      if resp && !resp.empty?
        JSON.parse(resp)
      else
        JSON.parse(%({}))
      end
    end

    def self.resource(kind, resource_name) : JSON::Any
      LOGGING.debug "kubectl get kind: #{kind} resource name: #{resource_name}"
      resp = `kubectl get #{kind} #{resource_name} -o json`
      LOGGING.debug "kubectl get resource: #{resp}"
      if resp && !resp.empty?
        JSON.parse(resp)
      else
        JSON.parse(%({}))
      end
    end

    def self.save_manifest(deployment_name, output_file) 
      resp = `kubectl get deployment #{deployment_name} -o yaml  > #{output_file}`
      LOGGING.debug "kubectl save_manifest: #{resp}"
      $?.success?
    end

    def self.deployments : JSON::Any
      resp = `kubectl get deployments -o json`
      LOGGING.debug "kubectl get deployment: #{resp}"
      if resp && !resp.empty?
        JSON.parse(resp)
      else
        JSON.parse(%({}))
      end
    end

    def self.deployment_containers(deployment_name) : JSON::Any 
      resource_containers("deployment", deployment_name)
    end

    def self.resource_containers(kind, resource_name) : JSON::Any 
      LOGGING.debug "kubectl get resource containers kind: #{kind} resource_name: #{resource_name}"
      unless kind.downcase == "service" ## services have no containers
        resp = resource(kind, resource_name).dig?("spec", "template", "spec", "containers")
      end
      LOGGING.debug "kubectl get resource containers: #{resp}"
      if resp && resp.as_a.size > 0
        resp
      else
        JSON.parse(%([]))
      end
    end

    def self.resource_volumes(kind, resource_name) : JSON::Any 
      LOGGING.debug "kubectl get resource volumes kind: #{kind} resource_name: #{resource_name}"
      unless kind.downcase == "service" ## services have no volumes
        resp = resource(kind, resource_name).dig?("spec", "template", "spec", "volumes")
      end
      LOGGING.debug "kubectl get resource volumes: #{resp}"
      if resp && resp.as_a.size > 0
        resp
      else
        JSON.parse(%([]))
      end
    end

    def self.secrets : JSON::Any
      resp = `kubectl get secrets -o json`
      LOGGING.debug "kubectl get secrets: #{resp}"
      if resp && !resp.empty?
        JSON.parse(resp)
      else
        JSON.parse(%({}))
      end
    end

    def self.resource_desired_is_available?(kind : String, resource_name)
      resp = `kubectl get #{kind} #{resource_name} -o=yaml`
      replicas_applicable = false
      case kind.downcase
      when "deployment", "statefulset", "replicaset" 
        replicas_applicable = true
        describe = Totem.from_yaml(resp)
        LOGGING.info("desired_is_available describe: #{describe.inspect}")
        desired_replicas = describe.get("status").as_h["replicas"].as_i
        LOGGING.info("desired_is_available desired_replicas: #{desired_replicas}")
        ready_replicas = describe.get("status").as_h["readyReplicas"]?
        unless ready_replicas.nil?
          ready_replicas = ready_replicas.as_i
        else
          ready_replicas = 0
        end
        LOGGING.info("desired_is_available ready_replicas: #{ready_replicas}")
      else
        replicas_applicable = false 
      end
      if replicas_applicable
        desired_replicas == ready_replicas
      else
        true
      end
    end
    def self.desired_is_available?(deployment_name)
      resource_desired_is_available?("deployment", deployment_name)
    end

    def self.deployment_spec_labels(deployment_name) : JSON::Any 
      resource_spec_labels("deployment", deployment_name)
    end
    def self.resource_spec_labels(kind, resource_name) : JSON::Any 
      LOGGING.debug "resource_labels kind: #{kind} resource_name: #{resource_name}"
      resp = resource(kind, resource_name).dig?("spec", "template", "metadata", "labels")
      LOGGING.debug "resource_labels: #{resp}"
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
