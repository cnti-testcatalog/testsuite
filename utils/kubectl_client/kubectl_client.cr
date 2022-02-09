require "totem"
require "colorize"
# require "halite"

# todo put in a separate library. it shold go under ./tools for now
module KubectlClient
  alias K8sManifest = JSON::Any
  alias K8sManifestList = Array(JSON::Any)
  WORKLOAD_RESOURCES = {deployment: "Deployment",
                        service: "Service",
                        pod: "Pod",
                        replicaset: "ReplicaSet",
                        statefulset: "StatefulSet",
                        daemonset: "DaemonSet"}

  # https://www.capitalone.com/tech/cloud/container-runtime/
  # todo add podman
  OCI_RUNTIME_REGEX = /containerd|docker|runc|railcar|crun|rkt|gviso|nabla|runv|clearcontainers|kata|cri-o/i

  module ShellCmd
    def self.run(cmd, log_prefix, force_output=false)
      Log.info { "#{log_prefix} command: #{cmd}" }
      status = Process.run(
        cmd,
        shell: true,
        output: output = IO::Memory.new,
        error: stderr = IO::Memory.new
      )
      if force_output == false
        Log.debug { "#{log_prefix} output: #{output.to_s}" }
      else
        Log.info { "#{log_prefix} output: #{output.to_s}" }
      end
      Log.info { "#{log_prefix} stderr: #{stderr.to_s}" }
      {status: status, output: output.to_s, error: stderr.to_s}
    end
  end
  
  def self.wait(cmd)
    status = Process.run("kubectl wait #{cmd}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    Log.info { "KubectlClient.wait output: #{output.to_s}" }
    Log.info { "KubectlClient.wait stderr: #{stderr.to_s}" }
    {status: status, output: output, error: stderr}
  end

  def self.logs(pod_name, options="")
    status = Process.run("kubectl logs #{pod_name} #{options}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    Log.debug { "KubectlClient.logs output: #{output.to_s}" }
    Log.info { "KubectlClient.logs stderr: #{stderr.to_s}" }
    {status: status, output: output, error: stderr}
  end

  def self.describe(kind, resource_name)
    # kubectl describe requiretags block-latest-tag 
    status = Process.run("kubectl describe #{kind} #{resource_name}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    Log.debug { "KubectlClient.describe output: #{output.to_s}" }
    Log.info { "KubectlClient.describe stderr: #{stderr.to_s}" }
    {status: status, output: output, error: stderr}
  end

  def self.exec(command, force_output=false)
    cmd = "kubectl exec #{command}"
    ShellCmd.run(cmd, "KubectlClient.exec", force_output)
  end

  def self.cp(command)
    cmd = "kubectl cp #{command}"
    ShellCmd.run(cmd, "KubectlClient.cp")
  end

  def self.server_version()
    Log.debug { "KubectlClient.server_version" }
    result = ShellCmd.run("kubectl version --output json", "KubectlClient.server_version", true)
    version = JSON.parse(result[:output])["serverVersion"]["gitVersion"].as_s
    version = version.gsub("v", "")
    Log.info { "KubectlClient.server_version: #{version}" }
    version
  end

  module Rollout
    def self.status(deployment_name, timeout="30s") : Bool
      cmd = "kubectl rollout status deployment/#{deployment_name} --timeout=#{timeout}"
      result = ShellCmd.run(cmd, "KubectlClient::Rollout.status")
      result[:status].success?
    end

    def self.resource_status(kind, resource_name, timeout="30s") : Bool
      cmd = "kubectl rollout status #{kind}/#{resource_name} --timeout=#{timeout}"
      result = ShellCmd.run(cmd, "KubectlClient::Rollout.status")
      Log.debug { "rollout status: #{result[:status].success?}" }
      result[:status].success?
    end

    def self.undo(deployment_name) : Bool
      cmd = "kubectl rollout undo deployment/#{deployment_name}"
      result = ShellCmd.run(cmd, "KubectlClient::Rollout.undo")
      Log.debug { "rollback status: #{result[:status].success?}" }
      result[:status].success?
    end
  end

  module Annotate
    def self.run(cli)
      cmd = "kubectl annotate #{cli}"
      ShellCmd.run(cmd, "KubectlClient::Annotate.run")
    end
  end

  module Create
    def self.command(cli : String)
      cmd = "kubectl create #{cli}"
      result = ShellCmd.run(cmd, "KubectlClient::Create.command")
      result[:status].success?
    end
  end

  module Apply
    def self.file(file_name, options="")
      cmd = "kubectl apply -f #{file_name} #{options}"
      ShellCmd.run(cmd, "KubectlClient::Apply.file")
    end

    def self.validate(file_name) : Bool
      # this hits the server btw (so you need a valid K8s cluster)
      cmd = "kubectl apply --validate=true --dry-run=client -f #{file_name}"
      result = ShellCmd.run(cmd, "KubectlClient::Apply.validate")
      result[:status].success?
    end
  end

  module Patch
    def self.spec(kind : String, resource : String, spec_input : String, namespace : String? = nil)
      namespace_opt = ""
      if namespace != nil
        namespace_opt = "-n #{namespace}"
      end
      cmd = "kubectl patch #{kind} #{resource} #{namespace_opt} -p '#{spec_input}'"
      ShellCmd.run(cmd, "KubectlClient::Patch.spec")
    end
  end

  module Scale
    def self.command(cli)
      cmd = "kubectl scale #{cli}"
      ShellCmd.run(cmd, "KubectlClient::Scale.command")
    end
  end

  module Delete
    def self.command(command)
      cmd = "kubectl delete #{command}"
      ShellCmd.run(cmd, "KubectlClient::Delete.command")
    end

    def self.file(file_name)
      cmd = "kubectl delete -f #{file_name}"
      ShellCmd.run(cmd, "KubectlClient::Delete.file")
    end
  end

  module Cordon
    def self.command(command)
      cmd = "kubectl cordon #{command}"
      ShellCmd.run(cmd, "KubectlClient::Cordon.command")
    end
  end

  module Set
    def self.image(deployment_name, container_name, image_name, version_tag=nil) : Bool
      # use --record when setting image to have history
      #TODO check if image exists in repo? DockerClient::Get.image and image_by_tags
      cmd = ""
      if version_tag
        cmd = "kubectl set image deployment/#{deployment_name} #{container_name}=#{image_name}:#{version_tag} --record"
      else
        cmd = "kubectl set image deployment/#{deployment_name} #{container_name}=#{image_name} --record"
      end
      result = ShellCmd.run(cmd, "KubectlClient::Set.image")
      result[:status].success?
    end
  end

  #TODO move this out into its own file
  module Get
    @@schedulable_nodes_template : String = <<-GOTEMPLATE.strip
    {{- range .items -}}
      {{$taints:=""}}
      {{- range .spec.taints -}}
        {{- if eq .effect "NoSchedule" -}}
          {{- $taints = print $taints .key "," -}}
        {{- end -}}
      {{- end -}}
      {{- if not $taints -}}
        {{- .metadata.name}}
        {{- "\\n" -}}
      {{end -}}
    {{- end -}}
    GOTEMPLATE

    def self.privileged_containers(namespace="--all-namespaces")
      cmd = "kubectl get pods #{namespace} -o jsonpath='{.items[*].spec.containers[?(@.securityContext.privileged==true)].name}'"
      result = ShellCmd.run(cmd, "KubectlClient::Get.privileged_containers")

      # TODO parse this as json
      resp = result[:output].split(" ").uniq
      Log.debug { "kubectl get privileged_containers: #{resp}" }
      resp
    end

    def self.namespaces(cli = "") : JSON::Any
      cmd = "kubectl get namespaces -o json #{cli}"
      result = ShellCmd.run(cmd, "KubectlClient::Get.namespaces")
      response = result[:output]

      if result[:status].success? && !response.empty?
        return JSON.parse(response)
      end
      JSON.parse(%({}))
    end

    def self.nodes() : JSON::Any
      # TODO should this be all namespaces?
      cmd = "kubectl get nodes -o json"
      result = ShellCmd.run(cmd, "KubectlClient::Get.nodes")
      JSON.parse(result[:output])
    end

    def self.endpoints(all_namespaces=false) : K8sManifest
      option = all_namespaces ? "--all-namespaces" : ""
      cmd = "kubectl get endpoints #{option} -o json"
      result = ShellCmd.run(cmd, "KubectlClient::Get.endpoints")
      response = result[:output]
      if result[:status].success? && !response.empty?
        return JSON.parse(response)
      end
      JSON.parse(%({}))
    end

    def self.pods(all_namespaces=true) : K8sManifest 
      option = all_namespaces ? "--all-namespaces" : ""
      cmd = "kubectl get pods #{option} -o json"
      result = ShellCmd.run(cmd, "KubectlClient::Get.pods")
      response = result[:output]
      if result[:status].success? && !response.empty?
        return JSON.parse(response)
      end
      JSON.parse(%({}))
    end
   
    # todo put this in a manifest module
    def self.resource_map(k8s_manifest, &block)
      if nodes["items"]?
        items = nodes["items"].as_a.map do |item|
          if nodes["metadata"]?
            metadata = nodes["metadata"]
          else
            metadata = JSON.parse(%({}))
          end
          yield item, metadata
        end
        Log.debug { "resource_map items : #{items}" }
        items
      else
        [JSON.parse(%({}))]
      end
    end

    # todo put this in a manifest module
    def self.resource_select(k8s_manifest, &block)
      if nodes["items"]?
        items = nodes["items"].as_a.select do |item|
          if nodes["metadata"]?
            metadata = nodes["metadata"]
          else
            metadata = JSON.parse(%({}))
          end
          yield item, metadata
        end
        Log.debug { "resource_map items : #{items}" }
        items
      else
         [] of JSON::Any
      end
    end

    def self.schedulable_nodes_list : Array(JSON::Any)   
      retry_limit = 50
      retries = 1
      empty_json_any = [] of JSON::Any
      nodes = empty_json_any
      # Get.nodes seems to have failures sometimes
      until (nodes != empty_json_any) || retries > retry_limit
        nodes = KubectlClient::Get.resource_select(KubectlClient::Get.nodes) do |item, metadata|
          taints = item.dig?("spec", "taints")
          Log.debug { "taints: #{taints}" }
          if (taints && taints.as_a.find{ |x| x.dig?("effect") == "NoSchedule" })
            # EMPTY_JSON 
            false 
          else
            # item
            true
          end
        end
      end
      if nodes == empty_json_any
        Log.error { "nodes empty: #{nodes}" }
      end
      Log.debug { "nodes: #{nodes}" }
      nodes
    end

    def self.nodes_by_resource(resource) : Array(JSON::Any)   
      retry_limit = 50
      retries = 1
      empty_json_any = [] of JSON::Any
      nodes = empty_json_any
      # Get.nodes seems to have failures sometimes
      until (nodes != empty_json_any) || retries > retry_limit
        nodes = KubectlClient::Get.resource_select(KubectlClient::Get.nodes) do |item, metadata|
          item.dig?("metadata", "name") == resourc.dig?("metadata", "name")
        end
      end
      if nodes == empty_json_any
        Log.error { "nodes empty: #{nodes}" }
      end
      Log.debug { "nodes: #{nodes}" }
      nodes
    end

    def self.pods_by_nodes(nodes_json : Array(JSON::Any))
      Log.info { "pods_by_node" }
      nodes_json.map { |item|
        Log.info { "items labels: #{item.dig?("metadata", "labels")}" }
        node_name = item.dig?("metadata", "labels", "kubernetes.io/hostname")
        Log.debug { "NodeName: #{node_name}" }
        pods = KubectlClient::Get.pods.as_h["items"].as_a.select do |pod| 
          if pod.dig?("spec", "nodeName") == "#{node_name}"
            Log.debug { "pod: #{pod}" }
            pod_name = pod.dig?("metadata", "name")
            Log.debug { "PodName: #{pod_name}" }
            true
          else
            Log.debug { "spec node_name: No Match: #{node_name}" }
            false
          end
        end
      }.flatten
    end

    #todo default flag for schedulable pods vs all pods
    def self.pods_by_resource(resource_yml : JSON::Any) : K8sManifestList 
      Log.info { "pods_by_resource" }
      Log.debug { "pods_by_resource resource: #{resource_yml}" }
      return [resource_yml] if resource_yml["kind"].as_s.downcase == "pod"
      Log.info { "resource kind: #{resource_yml["kind"]}" }
      
      #todo change this to kubectl get all pods --all-namespaces -o json for performance
      pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
      Log.info { "resource kind: #{resource_yml["kind"]}" }
      name = resource_yml["metadata"]["name"]?
      Log.info { "pods_by_resource name: #{name}" }
      if name
        #todo deployment labels may not match template metadata labels.  
        # -- may need to match on selector matchlabels instead
        labels = KubectlClient::Get.resource_spec_labels(resource_yml["kind"], name).as_h
        Log.info { "pods_by_resource labels: #{labels}" }
        KubectlClient::Get.pods_by_labels(pods, labels)
      else
        Log.info { "pods_by_resource name is nil" }
        [] of JSON::Any
      end
    end

    def self.pods_by_labels(pods_json : Array(JSON::Any), labels : Hash(String, JSON::Any))
      Log.info { "pods_by_label labels: #{labels}" }
      pods_json.select do |pod|
        if labels == Hash(String, JSON::Any).new
          match = false
        else
          match = true
        end
        #todo deployment labels may not match template metadata labels.  
        # -- may need to match on selector matchlabels instead
        labels.map do |key, value|
          if pod.dig?("metadata", "labels", key) == value
            match = true
          else
            Log.debug { "metadata labels: No Match #{value}" }
            match = false
          end
        end
        match
      end 
    end

    def self.pods_by_label(pods_json : Array(JSON::Any), label_key, label_value)
      Log.info { "pods_by_label" }
      pods_json.select do |pod|
        if pod.dig?("metadata", "labels", label_key) == label_value
          Log.debug { "pod: #{pod}" }
          true
        else
          Log.debug { "metadata labels: No Match #{label_value}" }
          false
        end
      end 
    end

    def self.deployment(deployment_name) : JSON::Any
      cmd = "kubectl get deployment #{deployment_name} -o json"
      result = ShellCmd.run(cmd, "KubectlClient::Get.deployment")
      response = result[:output]
      if result[:status].success? && !response.empty?
        JSON.parse(resp)
      else
        JSON.parse(%({}))
      end
    end

    def self.resource(kind, resource_name, namespace : String? = nil) : JSON::Any
      namespace_opt = ""
      if namespace != nil
        namespace_opt = "-n #{namespace.gsub("--namespace ", "").gsub("-n ", "") if namespace}"
      end
      cmd = "kubectl get #{kind} #{resource_name} -o json #{namespace_opt}"
      result = ShellCmd.run(cmd, "KubectlClient::Get.resource")
      response = result[:output]

      if result[:status].success? && !response.empty?
        return JSON.parse(response)
      end
      JSON.parse(%({}))
    end

    def self.save_manifest(deployment_name, output_file) : Bool
      cmd = "kubectl get deployment #{deployment_name} -o yaml  > #{output_file}"
      result = ShellCmd.run(cmd, "KubectlClient::Get.safe_manifest")
      result[:status].success?
    end

    def self.deployments : JSON::Any
      cmd = "kubectl get deployments -o json"
      result = ShellCmd.run(cmd, "KubectlClient::Get.deployments")
      response = result[:output]

      if result[:status].success? && !response.empty?
        return JSON.parse(resp)
      end
      JSON.parse(%({}))
    end

    def self.services : JSON::Any
      cmd = "kubectl get services -o json"
      result = ShellCmd.run(cmd, "KubectlClient::Get.services")
      response = result[:output]

      if result[:status].success? && !response.empty?
        resp = JSON.parse(response)
      else
        resp = JSON.parse(%({}))
      end
      resp
    end
    def self.service_by_digest(container_digest)
      Log.info { "service_by_digest container_digest: #{container_digest}" }
      services = KubectlClient::Get.services 
      matched_service = JSON.parse(%({}))
      services["items"].as_a.each do |service|
        Log.debug { "service_by_digest service: #{service}" }
        service_labels = service.dig?("spec", "selector")
        next unless service_labels
        # pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
        pods = KubectlClient::Get.pods
        service_pods = KubectlClient::Get.pods_by_labels(pods["items"].as_a, service_labels.as_h)

        service_pods.each do |service_pod|
          Log.debug { "service_by_digest service_pod: #{service_pod}" }
          statuses = service_pod.dig("status", "containerStatuses")
          statuses.as_a.each do |status|
            Log.debug { "service_by_digest status: #{status}" }
            matched_service = service if status.dig("imageID").as_s.includes?(container_digest)
          end
        end

      end
      Log.info { "service_by_digest matched_service: #{matched_service}" }
      matched_service
    end

    def self.pods_by_service(service)
      Log.info { "pods_by_service service: #{service}" }
      service_labels = service.dig?("spec", "selector")
      return unless service_labels
      pods = KubectlClient::Get.pods
      service_pods = KubectlClient::Get.pods_by_labels(pods["items"].as_a, service_labels.as_h)
    end

    def self.pods_by_digest(container_digest)
      matched_pod = [] of JSON::Any  
      pods = KubectlClient::Get.pods
      pods["items"].as_a.each do |pod|
        Log.debug { "pod_by_digest pod: #{pod}" }
        statuses = pod.dig?("status", "containerStatuses")
        if statuses
          statuses.as_a.each do |status|
            Log.debug { "pod_by_digest status: #{status}" }
            matched_pod << pod if status.dig("imageID").as_s.includes?("#{container_digest}")
          end
        end
      end
      matched_pod
    end

    def self.service_url_by_digest(container_digest)
      Log.info { "service_url_by_digest container_digest: #{container_digest}" }
      matched_service = service_by_digest(container_digest)
      service_name = service.dig?("metadata", "name")
      ports = service.dig?("spec", "ports")
      
      url_list = ports.map do |port|
        "#{service_name}:#{port["port"]}"
      end

      Log.info { "service_url_by_digest url_list: #{url_list}" }
      url_list
    end

    def self.deployment_containers(deployment_name) : JSON::Any
      resource_containers("deployment", deployment_name)
    end

    def self.resource_containers(kind, resource_name, namespace : String? = nil) : JSON::Any
      Log.debug { "kubectl get resource containers kind: #{kind} resource_name: #{resource_name} namespace: #{namespace}" }
      case kind.downcase
      when "pod"
        resp = resource(kind, resource_name, namespace).dig?("spec", "containers")
      when "deployment", "statefulset", "replicaset", "daemonset"
        resp = resource(kind, resource_name, namespace).dig?("spec", "template", "spec", "containers")
        # unless kind.downcase == "service" ## services have no containers
      end

      Log.debug { "kubectl get resource containers: #{resp}" }
      if resp && resp.as_a.size > 0
        resp
      else
        JSON.parse(%([]))
      end
    end

    #todo pass in namespace
    def self.resource_volumes(kind, resource_name, namespace="default") : JSON::Any
      Log.info { "kubectl get resource volumes kind: #{kind} resource_name: #{resource_name} namespace: #{namespace}" }
      unless kind.downcase == "service" ## services have no volumes
        resp = resource(kind, resource_name, namespace).dig?("spec", "template", "spec", "volumes")
      end

      Log.info { "kubectl get resource volumes: #{resp}" }
      if resp && resp.as_a.size > 0
        resp
      else
        JSON.parse(%([]))
      end
    end

    def self.secrets : JSON::Any
      cmd = "kubectl get secrets -o json"
      result = ShellCmd.run(cmd, "KubectlClient::Get.secrets")
      response = result[:output]

      if result[:status].success? && !response.empty?
        return JSON.parse(response)
      end
      JSON.parse(%({}))
    end

    def self.configmaps : JSON::Any
      cmd = "kubectl get configmaps -o json"
      result = ShellCmd.run(cmd, "KubectlClient::Get.configmaps")
      response = result[:output]

      if result[:status].success? && !response.empty?
        return JSON.parse(response)
      end
      JSON.parse(%({}))
    end

    def self.configmap(name) : JSON::Any
      cmd = "kubectl get configmap #{name} -o json"
      result = ShellCmd.run(cmd, "KubectlClient::Get.configmap")
      response = result[:output]

      if result[:status].success? && !response.empty?
        return JSON.parse(response)
      end
      JSON.parse(%({}))
    end

    def self.wait_for_install(deployment_name, wait_count : Int32 = 180, namespace="default")
      resource_wait_for_install("deployment", deployment_name, wait_count, namespace)
    end

    def self.wait_for_critools(wait_count : Int32 = 10)
      pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
      pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")
      ready = false
      timeout = wait_count
      `touch /tmp/testfile`
      pods.map do |pod| 
        until (ready == true || timeout <= 0) 
          sh = KubectlClient.cp("/tmp/testfile #{pod.dig?("metadata", "name")}:/tmp/test")
          if sh[:status].success?
            ready = true
          end
          sleep 1
          timeout = timeout - 1 
          Log.info { "Waiting for CRI-Tools Pod" }
        end
        if timeout <= 0
          break
        end
      end
    end

    def self.resource_ready?(kind, namespace, resource_name, kubeconfig=nil) : Bool
      ready = false
      case kind.downcase
      when "pod"
        pod_ready = KubectlClient::Get.pod_status(pod_name_prefix: resource_name, namespace: namespace, kubeconfig: kubeconfig).split(",")[2]
        Log.info { "pod_ready: #{pod_ready}"}
        return pod_ready == "true"
      when "replicaset", "deployment", "statefulset"
        desired = replica_count(kind, namespace, resource_name, "{.status.replicas}", kubeconfig)
        unavailable = replica_count(kind, namespace, resource_name, "{.status.unavailableReplicas}", kubeconfig)
        current = replica_count(kind, namespace, resource_name, "{.status.readyReplicas}", kubeconfig)
        Log.info { "current_replicas: #{current}, desired_replicas: #{desired}, unavailable_replicas: #{unavailable}"  }

        ready = current == desired 
        
        if desired == 0 && unavailable >= 1
          ready = false
        end

        if (current == -1 || desired == -1)
          ready = false
        end
        
      when "daemonset"
        desired = replica_count(kind, namespace, resource_name, "{.status.desiredNumberScheduled}", kubeconfig)
        current = replica_count(kind, namespace, resource_name, "{.status.numberAvailable}", kubeconfig)
        unavailable = replica_count(kind, namespace, resource_name, "{.status.unavailableReplicas}", kubeconfig)
        Log.info { "current_replicas: #{current}, desired_replicas: #{desired}" }

        ready = current == desired
        
        if desired == 0 && unavailable >= 1
          ready = false
        end
        
        if (current == -1 || desired == -1)
          ready = false
        end
        
      else
        desired = replica_count(kind, namespace, resource_name, "{.status.replicas}", kubeconfig)
        current = replica_count(kind, namespace, resource_name, "{.status.readyReplicas}", kubeconfig)
        unavailable = replica_count(kind, namespace, resource_name, "{.status.unavailableReplicas}", kubeconfig)
        Log.info { "current_replicas: #{current}, desired_replicas: #{desired}" }

        ready = current == desired
        
        if desired == 0 && unavailable >= 1
          ready = false
        end

        if (current == -1 || desired == -1)
          ready = false
        end
      end
      ready
    end

    def self.replica_count(kind, namespace, resource_name, jsonpath, kubeconfig=nil) : Int32
      cmd = "kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='#{jsonpath}' #{kubeconfig ? "--kubeconfig " + kubeconfig : ""}"
      result = ShellCmd.run(cmd, "KubectlClient::Get.replica_count")
      return -1 if result[:output].empty?
      result[:output].to_i
    end

    def self.resource_wait_for_install(kind : String, resource_name : String, wait_count : Int32 = 180, namespace="default", kubeconfig=nil)
      # Not all cnfs have #{kind}.  some have only a pod.  need to check if the
      # passed in pod has a deployment, if so, watch the deployment.  Otherwise watch the pod
      Log.info { "resource_wait_for_install kind: #{kind} resource_name: #{resource_name} namespace: #{namespace} kubeconfig: #{kubeconfig}" }
      second_count = 0

      # Intialization
      is_ready = resource_ready?(kind, namespace, resource_name, kubeconfig)

      until is_ready || second_count > wait_count
        Log.info { "KubectlClient::Get.resource_wait_for_install attempt: #{second_count}; is_ready: #{is_ready}" }
        sleep 1
        is_ready = resource_ready?(kind, namespace, resource_name, kubeconfig)
        second_count = second_count + 1
      end

      Log.info { "is_ready kind/resource #{kind}, #{resource_name}: #{is_ready}" }
      return is_ready
    end

    #TODO add parameter and functionality that checks for individual pods to be successfully terminated
    def self.resource_wait_for_uninstall(kind : String, resource_name : String, wait_count : Int32 = 180, namespace="default")
      # Not all cnfs have #{kind}.  some have only a pod.  need to check if the
      # passed in pod has a deployment, if so, watch the deployment.  Otherwise watch the pod
      Log.info { "resource_wait_for_uninstall kind: #{kind} resource_name: #{resource_name} namespace: #{namespace}" }
      empty_hash = {} of String => JSON::Any 
      second_count = 0
      pod_ready : String | Nil
      #TODO use the kubectl client get
      all_kind = ShellCmd.run("kubectl get #{kind} --namespace=#{namespace}", "all_kind")

      resource_uninstalled = KubectlClient::Get.resource(kind, resource_name)
      Log.debug { "resource_uninstalled #{resource_uninstalled}" }
      
      until (resource_uninstalled && resource_uninstalled.as_h == empty_hash)  || second_count > wait_count
        Log.info { "second_count = #{second_count}" }
        sleep 1
        Log.debug { "wait command: kubectl get #{kind} --namespace=#{namespace}" }
        resource_uninstalled = KubectlClient::Get.resource(kind, resource_name) #todo add namespace
        Log.debug { "resource_uninstalled #{resource_uninstalled}" }
        second_count = second_count + 1
      end

        Log.info { "final resource_uninstalled #{resource_uninstalled}" }
      if (resource_uninstalled && resource_uninstalled.as_h == empty_hash)
        Log.info { "kind/resource #{kind}, #{resource_name} uninstalled." }
        true
      else
        Log.info { "kind/resource #{kind}, #{resource_name} is still present." }
        false
      end
    end

    #TODO make dockercluser reference generic
    def self.wait_for_install_by_apply(manifest_file, wait_count=180)
      Log.info { "wait_for_install_by_apply" }
      second_count = 0
      apply_result = KubectlClient::Apply.file(manifest_file)
      apply_resp = apply_result[:output]

      until (apply_resp =~ /dockercluster.infrastructure.cluster.x-k8s.io\/capd unchanged/) != nil && (apply_resp =~ /cluster.cluster.x-k8s.io\/capd unchanged/) != nil && (apply_resp =~ /kubeadmcontrolplane.controlplane.cluster.x-k8s.io\/capd-control-plane unchanged/) != nil && (apply_resp =~ /kubeadmconfigtemplate.bootstrap.cluster.x-k8s.io\/capd-md-0 unchanged/) !=nil && (apply_resp =~ /machinedeployment.cluster.x-k8s.io\/capd-md-0 unchanged/) != nil && (apply_resp =~ /machinehealthcheck.cluster.x-k8s.io\/capd-mhc-0 unchanged/) != nil || second_count > wait_count.to_i
        Log.info { "second_count = #{second_count}" }
        sleep 1
        apply_result = KubectlClient::Apply.file(manifest_file)
        apply_resp = apply_result[:output]
        second_count = second_count + 1
      end
    end

    def self.resource_desired_is_available?(kind : String, resource_name)
      cmd = "kubectl get #{kind} #{resource_name} -o=yaml"
      result = ShellCmd.run(cmd, "resource_desired_is_available?")
      resp = result[:output]

      replicas_applicable = false
      case kind.downcase
      when "deployment", "statefulset", "replicaset"
        replicas_applicable = true
        describe = Totem.from_yaml(resp)
        Log.info { "desired_is_available describe: #{describe.inspect}" }
        desired_replicas = describe.get("status").as_h["replicas"].as_i
        Log.info { "desired_is_available desired_replicas: #{desired_replicas}" }
        ready_replicas = describe.get("status").as_h["readyReplicas"]?
        unless ready_replicas.nil?
          ready_replicas = ready_replicas.as_i
        else
          ready_replicas = 0
        end
        Log.info { "desired_is_available ready_replicas: #{ready_replicas}" }
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


    # #TODO make a function that gives all the pods for a resource
    # def self.pods_for_resource(kind : String, resource_name)
    #   LOGGING.info "kind: #{kind}"
    #   LOGGING.info "resource_name: #{resource_name}"
    #   #TODO use get pods and use json
    #   # all_pods = `kubectl get pods #{field_selector} -o json'`
    #   all_pods = KubectlClient::Get.pods
    #   LOGGING.info("all_pods: #{all_pods}")
    #   # all_pod_names = all_pods[0].split(" ")
    #   # time_stamps = all_pods[1].split(" ")
    #   # pods_times = all_pod_names.map_with_index do |name, i|
    #   #   {:name => name, :time => time_stamps[i]}
    #   # end
    #   # LOGGING.info("pods_times: #{pods_times}")
    #   #
    #   # latest_pod_time = pods_times.reduce({:name => "not found", :time => "not_found"}) do | acc, i |
    #   all_pods
    #
    # end

    #TODO create a function for waiting for the complete uninstall of a resource 
    # that has pods
    #TODO get all resources for a cnf
    #TODO for a replicaset, deployment, statefulset, or daemonset list all pods
    #TODO check for terminated status of all pods to be complete (check if pod 
    # no longer exists)
    # def self.resource_wait_for_termination
    # end

    #TODO remove the need for a split and return name/ true /false in a hash
    #TODO add a spec for this
    def self.pod_status(pod_name_prefix, field_selector="", namespace="default", kubeconfig=nil)
      Log.info { "pod_status: #{pod_name_prefix}" }

      all_pods_cmd = "kubectl get pods #{field_selector} -o jsonpath='{.items[*].metadata.name},{.items[*].metadata.creationTimestamp}' #{kubeconfig ? "--kubeconfig " + kubeconfig : ""}"

      all_pods_result = Process.run(
        all_pods_cmd,
        shell: true,
        output: all_pods_stdout = IO::Memory.new,
        error: all_pods_stderr = IO::Memory.new
      )
      all_pods = all_pods_stdout.to_s.split(",")

      Log.info { all_pods }
      all_pod_names = all_pods[0].split(" ")
      time_stamps = all_pods[1].split(" ")
      pods_times = all_pod_names.map_with_index do |name, i|
        {:name => name, :time => time_stamps[i]}
      end
      Log.info { "pods_times: #{pods_times}" }

      latest_pod_time = pods_times.reduce({:name => "not found", :time => "not_found"}) do | acc, i |
        # if current i > acc
        Log.info { "ACC: #{acc}" }
        Log.info { "I:#{i}" }
        Log.info { "pod_name_prefix: #{pod_name_prefix}" }
        if (i[:name] =~ /#{pod_name_prefix}/).nil?
          Log.info { "pod_name_prefix: #{pod_name_prefix} does not match #{i[:name]}" }
          acc
        end
        if i[:name] =~ /#{pod_name_prefix}/
          Log.info { "pod_name_prefix: #{pod_name_prefix} matches #{i[:name]}" }
          # acc = i
          if acc[:name] == "not found"
            Log.info { "acc not found" }
            # if there is no previous time, use the time in the index
            previous_time = Time.parse!( "#{i[:time]} +00:00", "%Y-%m-%dT%H:%M:%SZ %z")
          else
            Log.info { "acc found. time: #{acc[:time]}" }
            previous_time = Time.parse!( "#{acc[:time]} +00:00", "%Y-%m-%dT%H:%M:%SZ %z")
          end
          new_time = Time.parse!( "#{i[:time]} +00:00", "%Y-%m-%dT%H:%M:%SZ %z")
          if new_time >= previous_time
            acc = i
          else
            acc
          end
        else
          acc
        end
      end
      Log.info { "latest_pod_time: #{latest_pod_time}" }

      if latest_pod_time[:name]
        pod = latest_pod_time[:name]
      else
        pod = ""
      end
      # pod = all_pod_names[time_stamps.index(latest_time).not_nil!]
      # pod = all_pods.select{ | x | x =~ /#{pod_name_prefix}/ }
      Log.info { "Pods Found: #{pod}" }
      # TODO refactor to return container statuses
      status = "#{pod_name_prefix},NotFound,false"
      if pod != "not found"
        cmd = "kubectl get pods #{pod} -o jsonpath='{.metadata.name},{.status.phase},{.status.containerStatuses[*].ready}' #{kubeconfig ? "--kubeconfig " + kubeconfig : ""}"
        result = ShellCmd.run(cmd, "pod_status")
        status = result[:output]
        Log.debug { "pod_status status before parse: #{status}" }
        status = status.gsub(" ", ",") # handle mutiple containers
        Log.debug { "pod_status status after parse: #{status}" }
      else
        Log.info { "pod: #{pod_name_prefix} is NOT found" }
      end
      Log.info { "pod_status status: #{status}" }
      status
    end

    def self.node_status(node_name)
      cmd = "kubectl get nodes #{node_name} -o jsonpath='{.status.conditions[?(@.type == \"Ready\")].status}'"
      result = ShellCmd.run(cmd, "KubectlClient::Get.node_status")
      result[:output]
    end

    def self.deployment_spec_labels(deployment_name) : JSON::Any
      resource_spec_labels("deployment", deployment_name)
    end
    def self.resource_spec_labels(kind, resource_name) : JSON::Any
      Log.debug { "resource_labels kind: #{kind} resource_name: #{resource_name}" }
      if kind.as_s.downcase == "service"
        resp = resource(kind, resource_name).dig?("spec", "selector")
      else
        resp = resource(kind, resource_name).dig?("spec", "template", "metadata", "labels")
      end
      Log.debug { "resource_labels: #{resp}" }
      if resp
        resp
      else
        JSON.parse(%({}))
      end
    end

    def self.container_image_tags(deployment_containers) : Array(NamedTuple(image: String,
                                                                            tag: String | Nil))
      image_tags = deployment_containers.as_a.map do |container|
        Log.debug { "container (should have image and tag): #{container}" }
        {image: container.as_h["image"].as_s.rpartition(":")[0],
         #TODO an image may not have a tag
         tag: container.as_h["image"].as_s.rpartition(":")[2]?}
      end
      Log.debug { "image_tags: #{image_tags}" }
      image_tags
    end

    def self.worker_nodes : Array(String)
      # Full command:
      #
      # kubectl get nodes --selector='!node-role.kubernetes.io/master' -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ "\\n"}}{{end}}{{end}}'

      cmd = "kubectl get nodes --selector='!node-role.kubernetes.io/master' -o 'go-template=#{@@schedulable_nodes_template}'"
      result = ShellCmd.run(cmd, "KubectlClient::Get.worker_nodes")
      result[:output].split("\n")
    end

    def self.schedulable_nodes : Array(String)
      # Full command:
      #
      # kubectl get nodes -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ "\\n"}}{{end}}{{end}}'

      cmd = "kubectl get nodes -o 'go-template=#{@@schedulable_nodes_template}'"
      result = ShellCmd.run(cmd, "KubectlClient::Get.schedulable_nodes")
      result[:output].split("\n")
    end

    def self.pv : JSON::Any
      # TODO should this be all namespaces?
      cmd = "kubectl get pv -o json"
      result = ShellCmd.run(cmd, "KubectlClient::Get.pv")
      response = result[:output]
      return JSON.parse(response)
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
          Log.info { ex.message }
          nil
        end
      end.compact
      Log.debug { "pv items : #{items}" }
      items
    end

    def self.container_runtime
      nodes["items"][0]["status"]["nodeInfo"]["containerRuntimeVersion"].as_s
    end

    def self.container_runtimes
      runtimes = nodes["items"].as_a.map do |x|
        x["status"]["nodeInfo"]["containerRuntimeVersion"].as_s
      end
      Log.info { "runtimes: #{runtimes}" }
      runtimes.uniq
    end

    # *pod_exists* returns true if a pod containing *pod_name* exists, regardless of status.
    # If *check_ready* is set to true, *pod_exists* validates that the pod exists and
    # has a ready status of true
    def self.pod_exists?(pod_name, check_ready=false, all_namespaces=false)
      Log.debug { "pod_exists? pod_name: #{pod_name}" }
      exists = pods(all_namespaces)["items"].as_a.any? do |x|
        (name_comparison = x["metadata"]["name"].as_s? =~ /#{pod_name}/
        (x["metadata"]["name"].as_s? =~ /#{pod_name}/) ||
          (x["metadata"]["generateName"]? && x["metadata"]["generateName"].as_s? =~ /#{pod_name}/)) &&
        (check_ready && (x["status"]["conditions"].as_a.find{|x| x["type"].as_s? == "Ready"} && x["status"].as_s? == "True") || check_ready==false)
      end
      Log.debug { "pod exists: #{exists}" }
      exists
    end

    def self.all_pod_statuses
      statuses = pods["items"].as_a.map do |x|
        x["status"]
      end
      Log.debug { "pod statuses: #{statuses}" }
      statuses
    end

    def self.all_pod_container_statuses
      statuses = all_pod_statuses.map do |x|
        # todo there are some pods that dont have containerStatuses
        x["containerStatuses"].as_a
      end
      statuses
    end

    def self.all_container_repo_digests
      imageids = all_pod_container_statuses.reduce([] of String) do |acc, x|
        acc | x.map{|i| i["imageID"].as_s}
      end
      Log.debug { "pod container image ids: #{imageids}" }
      imageids
    end

    def self.pod_statuses_by_nodes(nodes)
      pods = KubectlClient::Get.pods_by_nodes(nodes)
      Log.debug { "pod_statuses_by_nodes pods_by_nodes pods: #{pods}" }
      statuses = pods.map do |x|
        x["status"]
      end
      Log.debug { "pod_statuses_by_nodes statuses: #{statuses}" }
      statuses
    end

    def self.pod_container_statuses_by_nodes(nodes)
      statuses = pod_statuses_by_nodes(nodes).map do |x|
        # todo there are some pods that dont have containerStatuses
        x["containerStatuses"].as_a if x["containerStatuses"]?
      end
      Log.debug { "pod_container_statuses_by_nodes containerStatuses: #{statuses}" }
      statuses
    end

    def self.container_digests_by_nodes(nodes)
      Log.debug { "container_digests_by_nodes nodes: #{nodes}" }
      imageids = pod_container_statuses_by_nodes(nodes).reduce([] of String) do |acc, x|
        if x
          acc | x.map{|i| i["imageID"].as_s}
        else
          acc
        end
      end
      Log.info { "container_digests_by_nodes image ids: #{imageids}" }
      imageids
    end

    def self.container_images_by_nodes(nodes)
      Log.debug { "container_images_by_nodes nodes: #{nodes}" }
      images = pod_container_statuses_by_nodes(nodes).reduce([] of String) do |acc, x|
        if x
          acc | x.map{|i| i["image"].as_s}
        else
          acc
        end
      end
      Log.info { "container_images_by_nodes images: #{images}" }
      images
    end

    def self.container_tag_from_image_by_nodes(image, nodes)
      Log.debug { "container_tag_from_image_by_nodes nodes: #{nodes}" }
      # TODO Remove duplicates & and support multiple?
      all_images = container_images_by_nodes(nodes)
      # matched_image = all_images.select{ | x | x =~ /#{image}/ }
      matched_image = all_images.select{ | x | x.includes?(image) }
      parsed_image = DockerClient.parse_image("#{matched_image[0]}") if matched_image.size > 0
      tags = parsed_image["tag"] if parsed_image
      Log.info { "container_tag_from_image_by_nodes tags: #{tags}" } if tags
      tags
    end

    def self.pods_by_digest_and_nodes(digest, nodes=KubectlClient::Get.nodes["items"].as_a)
      Log.info { "pods_by_digest_and_nodes" }
      digest_pods = nodes.map { |item|
        Log.info { "items labels: #{item.dig?("metadata", "labels")}" }
        node_name = item.dig?("metadata", "labels", "kubernetes.io/hostname")
        Log.debug { "NodeName: #{node_name}" }
        pods = KubectlClient::Get.pods.as_h["items"].as_a.select do |pod| 
          found = false
          #todo add another pod comparison for sha hash
          if pod["status"]["containerStatuses"]?
            found = pod["status"]["containerStatuses"].as_a.any? do |container_status|
              Log.debug { "container_status imageid: #{container_status["imageID"]}"}
              Log.debug { "pods_by_digest_and_nodes digest: #{digest}"}
              match_found = container_status["imageID"].as_s.includes?("#{digest}")
              Log.debug { "container_status match_found: #{match_found}"}
              match_found
            end
            Log.debug { "found pod: #{pod}"}
            pod_name = pod.dig?("metadata", "name")
            Log.debug { "found PodName: #{pod_name}" }
            if found && pod.dig?("spec", "nodeName") == "#{node_name}"
              Log.debug { "found pod and node: #{pod} #{node_name}" }
              true
            else
              Log.debug { "spec node_name: No Match: #{node_name}" }
              false
            end
          else
            Log.info { "no containerstatuses" }
            false
          end
        end
      }.flatten
      if digest_pods.empty?
        Log.info { "match not found for digest: #{digest}" }
        [EMPTY_JSON]
      else
        digest_pods
      end
    end
  end
end
