require "colorize"
require "kubectl_client"

module KernelIntrospection
  def self.parse_proc(ps_output)
    ps_output.split("\n").map{|x| x.to_i?}.compact
  end

  def self.parse_status(status_output)
    LOGGING.info "parse_status status_output: #{status_output}"
    status = status_output.split("\n").reduce(Hash(String, String).new) do |acc,x| 
      if (x.match(/(.*):(.*)/).try &.[1])
        acc.merge({(x.match(/(.*):(.*)/).try &.[1]) => "#{x.match(/(.*):(.*)/).try &.[2]}".strip})
      else
        acc
      end
    end
    if status == Hash(String, String).new
      nil
    else
      status 
    end
  end

  module Local
    #Exec with Pod Name & Container Name
    #kubectl exec -ti cluster-tools-5tlms --container cluster-tools-two -- cat /proc/1/status
  end

  # todo (optional) get the resource name for the pod name

  # todo get all the pods
  # todo get the pod name
  # todo return all container names in a pod
  # todo loop through all pids in the container 

  module K8s
    def self.proc(pod_name, container_name, namespace : String | Nil = nil)
      # todo if container_name nil, dont use container (assume one container)
      resp = KubectlClient.exec("-ti #{pod_name} --container #{container_name} -- ls /proc/", namespace: namespace)
      KernelIntrospection.parse_proc(resp[:output].to_s)
    end

    def self.cmdline(pod_name, container_name, pid, namespace : String | Nil = nil)
      # todo if container_name nil, dont use container (assume one container)
      resp = KubectlClient.exec("-ti #{pod_name} --container #{container_name} -- cat /proc/#{pid}/cmdline")
      resp[:output].to_s.strip
    end

    def self.status(pod_name, container_name, pid, namespace : String | Nil = nil)
      # todo if container_name nil, dont use container (assume one container)
      resp = KubectlClient.exec("-ti #{pod_name} --container #{container_name} -- cat /proc/#{pid}/status", namespace: namespace)
      KernelIntrospection.parse_status(resp[:output].to_s)
    end

    def self.status_by_proc(pod_name, container_name, namespace : String | Nil = nil)
      proc(pod_name, container_name, namespace).map { |pid|
        stat_cmdline = status(pod_name, container_name, pid, namespace)
        stat_cmdline.merge({"cmdline" => cmdline(pod_name, container_name, pid, namespace)}) if stat_cmdline
      }.compact
    end

    #todo overload with regex
    def self.find_first_process(process_name) : (Hash(Symbol, Hash(String | Nil, String) | Hash(String, String) | JSON::Any | String) | Nil) 
      ret = nil
      pods = KubectlClient::Get.pods
      Log.debug { "Pods: #{pods}" }
      pods["items"].as_a.map do |pod|
        pod_name = pod.dig("metadata", "name")
        Log.info { "pod_name: #{pod_name}" }
        pod_namespace = pod.dig("metadata", "namespace")
        Log.info { "pod_namespace: #{pod_namespace}" }
        containers = KubectlClient::Get.resource_containers("pod", "#{pod_name}", "#{pod_namespace}")
        containers.as_a.map do |container|
          container_name = container.dig("name")
          previous_process_type = "initial_name"
          Log.info { "container_name: #{container_name}" }
          Log.info { "pod_namespace: #{pod_namespace}" }
          statuses = KernelIntrospection::K8s.status_by_proc("#{pod_name}", "#{container_name}", "#{pod_namespace}")
          statuses.map do |status|
            Log.info {"Proccess Name: #{status["cmdline"]}" }
            if status["cmdline"] =~ /#{process_name}/
              ret = {:pod => pod, :container => container, :status => status, :cmdline => status["cmdline"]}
              Log.info { "status found: #{ret}" }
              break 
            end
          end
        end
      end
      ret
    end
  end
end
