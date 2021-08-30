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
  OCI_RUNTIME_REGEX = /containerd|docker|runc|railcar|crun|rkt|gviso|nabla|runv|clearcontainers|kata|cri-o/i

  module ShellCmd
    def self.run(cmd, log_prefix)
      Log.info { "#{log_prefix} command: #{cmd}" }
      status = Process.run(
        cmd,
        shell: true,
        output: output = IO::Memory.new,
        error: stderr = IO::Memory.new
      )
      Log.debug { "#{log_prefix} output: #{output.to_s}" }
      Log.debug { "#{log_prefix} stderr: #{stderr.to_s}" }
      {status: status, output: output.to_s, error: stderr.to_s}
    end
  end

  def self.logs(pod_name, container_name="")
    status = Process.run("kubectl logs #{pod_name} #{container_name}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    LOGGING.debug "KubectlClient.logs output: #{output.to_s}"
    LOGGING.debug "KubectlClient.logs stderr: #{stderr.to_s}"
    {status: status, output: output, error: stderr}
  end

  def self.exec(command)
    cmd = "kubectl exec #{command}"
    ShellCmd.run(cmd, "KubectlClient.exec")
  end

  def self.cp(command)
    cmd = "kubectl cp #{command}"
    ShellCmd.run(cmd, "KubectlClient.cp")
  end

  def self.server_version()
    Log.debug { "KubectlClient.server_version" }
    result = ShellCmd.run("kubectl version", "KubectlClient.server_version")

    # example
    # Server Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.16", GitCommit:"7a98bb2b7c9112935387825f2fce1b7d40b76236", GitTreeState:"clean", BuildDate:"2021-02-17T11:52:32Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"linux/amd64"}
    resp = result[:output].match /Server Version: version.Info{(Major:"(([0-9]{1,3})"\, )Minor:"([0-9]{1,3}[+]?)")/
    Log.debug { "KubectlClient.server_version match: #{resp}" }
    if resp
      version = "#{resp && resp.not_nil![3]}.#{resp && resp.not_nil![4]}.0"
    else
      version = ""
    end
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
    def self.file(file_name)
      cmd = "kubectl apply -f #{file_name}"
      ShellCmd.run(cmd, "KubectlClient::Apply.file")
    end

    def self.validate(file_name) : Bool
      # this hits the server btw (so you need a valid K8s cluster)
      cmd = "kubectl apply --validate=true --dry-run=client -f #{file_name}"
      result = ShellCmd.run(cmd, "KubectlClient::Apply.validate")
      result[:status].success?
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

    def self.pods(all_namespaces=true) : K8sManifest 
      option = all_namespaces ? "--all-namespaces" : ""
      cmd = "kubectl get pods #{option} -o json"
      result = ShellCmd.run(cmd, "KubectlClient::Get.pods")
      JSON.parse(result[:output])
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

    def self.pods_by_resource(resource_yml) : K8sManifestList
      Log.info { "pods_by_resource" }
      Log.debug { "pods_by_resource resource: #{resource_yml}" }
      return [resource_yml] if resource_yml["kind"].as_s.downcase == "pod"
      Log.info { "resource kind: #{resource_yml["kind"]}" }
      
      pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
      Log.info { "resource kind: #{resource_yml["kind"]}" }
      name = resource_yml["metadata"]["name"]?
      Log.info { "pods_by_resource name: #{name}" }
      if name
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
      case kind.downcase
      when "pod"
        resp = resource(kind, resource_name).dig?("spec", "containers")
      when  "deployment","statefulset","replicaset", "daemonset"
        resp = resource(kind, resource_name).dig?("spec", "template", "spec", "containers")
        # unless kind.downcase == "service" ## services have no containers
      end
      LOGGING.info "kubectl get resource containers: #{resp}"
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

    def self.configmaps : JSON::Any
      resp = `kubectl get configmaps -o json`
      LOGGING.debug "kubectl get configmaps: #{resp}"
      if resp && !resp.empty?
        JSON.parse(resp)
      else
        JSON.parse(%({}))
      end
    end

    def self.configmap(name) : JSON::Any
      LOGGING.info "KubectlClient.configmap command: kubectl get configmap #{name} -o json"
      status = Process.run("kubectl get configmap #{name} -o json",
                           shell: true,
                           output: output = IO::Memory.new,
                           error: stderr = IO::Memory.new)
      LOGGING.debug "KubectlClient.configmap output: #{output.to_s}"
      LOGGING.info "KubectlClient.configmap stderr: #{stderr.to_s}"

      if output.to_s && !output.to_s.empty?
        JSON.parse(output.to_s)
      else
        JSON.parse(%({}))
      end
    end

    def self.wait_for_install(deployment_name, wait_count : Int32 = 180, namespace="default")
      resource_wait_for_install("deployment", deployment_name, wait_count, namespace)
    end

    def self.resource_wait_for_install(kind : String, resource_name : String, wait_count : Int32 = 180, namespace="default")
      # Not all cnfs have #{kind}.  some have only a pod.  need to check if the
      # passed in pod has a deployment, if so, watch the deployment.  Otherwise watch the pod
      LOGGING.info "resource_wait_for_install kind: #{kind} resource_name: #{resource_name} namespace: #{namespace}"
      second_count = 0
      pod_ready : String | Nil
      current_replicas : String | Nil
      desired_replicas : String | Nil
      #TODO use the kubectl client get
      all_kind = `kubectl get #{kind} --namespace=#{namespace}`
      LOGGING.debug "all_kind #{all_kind}}"
      # Intialization
      case kind.downcase
      when "replicaset", "deployment", "statefulset"
        #TODO use the kubectl client get
        #TODO add extra params for kubectl client get
        desired_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.replicas}'`
        LOGGING.debug "desired_replicas #{desired_replicas}"
        current_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.readyReplicas}'`
        LOGGING.debug "current_replicas #{current_replicas}"
      when "daemonset"
        desired_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.desiredNumberScheduled}'`
        LOGGING.debug "desired_replicas #{desired_replicas}"
        current_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.numberAvailable}'`
        LOGGING.debug "current_replicas #{current_replicas}"
      when "pod"
        pod_ready = KubectlClient::Get.pod_status(pod_name_prefix: resource_name, namespace: namespace).split(",")[2] # true/false
      else
        desired_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.replicas}'`
        LOGGING.debug "desired_replicas #{desired_replicas}"
        current_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.readyReplicas}'`
        LOGGING.debug "current_replicas #{current_replicas}"
      end

        until (pod_ready && !pod_ready.empty? && pod_ready == "true") ||
            (current_replicas && desired_replicas && !current_replicas.empty? && current_replicas.to_i == desired_replicas.to_i) ||
            second_count > wait_count
        LOGGING.info("second_count = #{second_count}")
        sleep 1
        LOGGING.debug "wait command: kubectl get #{kind} --namespace=#{namespace}"
        all_kind = `kubectl get #{kind} --namespace=#{namespace}`
        case kind.downcase
        when "replicaset", "deployment", "statefulset"
          current_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.readyReplicas}'`
          desired_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.replicas}'`
        when "daemonset"
          current_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.numberAvailable}'`
          desired_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.desiredNumberScheduled}'`
        when "pod"
          #TODO remove split and return true /false
          pod_ready = KubectlClient::Get.pod_status(pod_name_prefix: resource_name, namespace: namespace).split(",")[2] # true/false
        else
          current_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.readyReplicas}'`
          desired_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.replicas}'`
        end
        LOGGING.debug "desired_replicas: #{desired_replicas}"
        LOGGING.debug "pod_ready: #{pod_ready}"
        LOGGING.info(all_kind)
        second_count = second_count + 1
      end

      LOGGING.info "final pod_ready: #{pod_ready}"
      LOGGING.info "final current_replicas: #{current_replicas}"
      if (pod_ready && !pod_ready.empty? && pod_ready == "true") ||
          (current_replicas && desired_replicas && !current_replicas.empty? && current_replicas.to_i == desired_replicas.to_i)
        LOGGING.info "kind/resource #{kind}, #{resource_name} found."
        true
      else
        LOGGING.info "kind/resource #{kind}, #{resource_name} not found."
        false
      end
    end

    #TODO add parameter and functionality that checks for individual pods to be successfully terminated
    def self.resource_wait_for_uninstall(kind : String, resource_name : String, wait_count : Int32 = 180, namespace="default")
      # Not all cnfs have #{kind}.  some have only a pod.  need to check if the
      # passed in pod has a deployment, if so, watch the deployment.  Otherwise watch the pod
      LOGGING.info "resource_wait_for_uninstall kind: #{kind} resource_name: #{resource_name} namespace: #{namespace}"
      empty_hash = {} of String => JSON::Any 
      second_count = 0
      pod_ready : String | Nil
      #TODO use the kubectl client get
      all_kind = `kubectl get #{kind} --namespace=#{namespace}`
      LOGGING.debug "all_kind #{all_kind}}"

      resource_uninstalled = KubectlClient::Get.resource(kind, resource_name)
      # resource_uninstalled = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.replicas}'`
      LOGGING.debug "resource_uninstalled #{resource_uninstalled}"
      
      until (resource_uninstalled && resource_uninstalled.as_h == empty_hash)  || second_count > wait_count
        LOGGING.info("second_count = #{second_count}")
        sleep 1
        LOGGING.debug "wait command: kubectl get #{kind} --namespace=#{namespace}"
        # all_kind = `kubectl get #{kind} --namespace=#{namespace}`
        resource_uninstalled = KubectlClient::Get.resource(kind, resource_name)
        LOGGING.debug "resource_uninstalled #{resource_uninstalled}}"
        second_count = second_count + 1
      end

        LOGGING.info "final resource_uninstalled #{resource_uninstalled}}"
      if (resource_uninstalled && resource_uninstalled.as_h == empty_hash)
        LOGGING.info "kind/resource #{kind}, #{resource_name} uninstalled."
        true
      else
        LOGGING.info "kind/resource #{kind}, #{resource_name} is still present."
        false
      end
    end

    #TODO make dockercluser reference generic
    def self.wait_for_install_by_apply(manifest_file, wait_count=180)
      LOGGING.info "wait_for_install_by_apply"
      second_count = 0
      apply_resp = `kubectl apply -f #{manifest_file}`
      LOGGING.info("apply response: #{apply_resp}")
      until (apply_resp =~ /dockercluster.infrastructure.cluster.x-k8s.io\/capd unchanged/) != nil && (apply_resp =~ /cluster.cluster.x-k8s.io\/capd unchanged/) != nil && (apply_resp =~ /kubeadmcontrolplane.controlplane.cluster.x-k8s.io\/capd-control-plane unchanged/) != nil && (apply_resp =~ /kubeadmconfigtemplate.bootstrap.cluster.x-k8s.io\/capd-md-0 unchanged/) !=nil && (apply_resp =~ /machinedeployment.cluster.x-k8s.io\/capd-md-0 unchanged/) != nil && (apply_resp =~ /machinehealthcheck.cluster.x-k8s.io\/capd-mhc-0 unchanged/) != nil || second_count > wait_count.to_i
        LOGGING.info("second_count = #{second_count}")
        sleep 1
        apply_resp = `kubectl apply -f #{manifest_file}`
        LOGGING.info("apply response: #{apply_resp}")
        second_count = second_count + 1
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
    def self.pod_status(pod_name_prefix, field_selector="", namespace="default")
      LOGGING.info "pod_status: #{pod_name_prefix}"
      all_pods = `kubectl get pods #{field_selector} -o jsonpath='{.items[*].metadata.name},{.items[*].metadata.creationTimestamp}'`.split(",")

      LOGGING.info(all_pods)
      all_pod_names = all_pods[0].split(" ")
      time_stamps = all_pods[1].split(" ")
      pods_times = all_pod_names.map_with_index do |name, i|
        {:name => name, :time => time_stamps[i]}
      end
      LOGGING.info("pods_times: #{pods_times}")

      latest_pod_time = pods_times.reduce({:name => "not found", :time => "not_found"}) do | acc, i |
        # if current i > acc
        LOGGING.info("ACC: #{acc}")
        LOGGING.info("I:#{i}")
        LOGGING.info("pod_name_prefix: #{pod_name_prefix}")
        if (i[:name] =~ /#{pod_name_prefix}/).nil?
          LOGGING.info "pod_name_prefix: #{pod_name_prefix} does not match #{i[:name]}"
          acc
        end
        if i[:name] =~ /#{pod_name_prefix}/
          LOGGING.info "pod_name_prefix: #{pod_name_prefix} matches #{i[:name]}"
          # acc = i
          if acc[:name] == "not found"
            LOGGING.info "acc not found"
            # if there is no previous time, use the time in the index
            previous_time = Time.parse!( "#{i[:time]} +00:00", "%Y-%m-%dT%H:%M:%SZ %z")
          else
            LOGGING.info "acc found. time: #{acc[:time]}"
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
      LOGGING.info("latest_pod_time: #{latest_pod_time}")

      if latest_pod_time[:name]
        pod = latest_pod_time[:name]
      else
        pod = ""
      end
      # pod = all_pod_names[time_stamps.index(latest_time).not_nil!]
      # pod = all_pods.select{ | x | x =~ /#{pod_name_prefix}/ }
      LOGGING.info "Pods Found: #{pod}"
      # TODO refactor to return container statuses
      status = "#{pod_name_prefix},NotFound,false"
      if pod != "not found"
        status = `kubectl get pods #{pod} -o jsonpath='{.metadata.name},{.status.phase},{.status.containerStatuses[*].ready}'`
        LOGGING.debug "pod_status status before parse: #{status}"
        status = status.gsub(" ", ",") # handle mutiple containers
        LOGGING.debug "pod_status status after parse: #{status}"
      else
        LOGGING.info "pod: #{pod_name_prefix} is NOT found"
      end
      LOGGING.info "pod_status status: #{status}"
      status
    end

    def self.node_status(node_name)
      all_nodes = `kubectl get nodes -o jsonpath='{.items[*].metadata.name}'`
      LOGGING.info(all_nodes)
      status = `kubectl get nodes #{node_name} -o jsonpath='{.status.conditions[?(@.type == "Ready")].status}'`
      status
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
        {image: container.as_h["image"].as_s.rpartition(":")[0],
         #TODO an image may not have a tag
         tag: container.as_h["image"].as_s.rpartition(":")[2]?}
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

  LOGGING = LogginGenerator.new
  class LogginGenerator
    macro method_missing(call)
      if {{ call.name.stringify }} == "debug"
        Log.debug {{{call.args[0]}}}
      end
      if {{ call.name.stringify }} == "info"
        Log.info {{{call.args[0]}}}
      end
      if {{ call.name.stringify }} == "warn"
        Log.warn {{{call.args[0]}}}
      end
      if {{ call.name.stringify }} == "error"
        Log.error {{{call.args[0]}}}
      end
      if {{ call.name.stringify }} == "fatal"
        Log.fatal {{{call.args[0]}}}
      end
    end
  end
end
