require "colorize"
require "./kubectl_client.cr"

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
    #kubectl exec -ti cri-tools-5tlms --container cri-tools-two -- cat /proc/1/status
  end

  # todo (optional) get the resource name for the pod name

  # todo get all the pods
  # todo get the pod name
  # todo return all container names in a pod
  # todo loop through all pids in the container 

  module K8s
    def self.proc(pod_name, container_name)
      resp = KubectlClient.exec("-ti #{pod_name} --container #{container_name} -- ls /proc/")
      KernelIntrospection.parse_proc(resp[:output].to_s)
    end

    def self.status(pod_name, container_name, pid)
      resp = KubectlClient.exec("-ti #{pod_name} --container #{container_name} -- cat /proc/#{pid}/status")
      KernelIntrospection.parse_status(resp[:output].to_s)
    end

    def self.status_by_proc(pod_name, container_name)
      proc(pod_name, container_name).map { |pid|
        status(pod_name, container_name, pid)
      }.compact 

    end
  end
end
