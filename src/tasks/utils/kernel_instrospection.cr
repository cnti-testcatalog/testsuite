require "colorize"
require "kubectl_client"

module KernelIntrospection
  def self.parse_proc(ps_output)
    ps_output.split("\n").map{|x| x.to_i?}.compact
  end

  def self.parse_status(status_output) : (Hash(String, String) | Nil) 
    LOGGING.debug "parse_status status_output: #{status_output}"
    status = status_output.split("\n").reduce(Hash(String, String).new) do |acc,x| 
      if (x.match(/(.*):(.*)/).try &.[1])
        acc.merge({ "#{(x.match(/(.*):(.*)/).try &.[1])}" => "#{x.match(/(.*):(.*)/).try &.[2]}".strip})
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

  def self.parse_ls(ls : String) : Array(String)
    Log.debug { "parse_ls ls: #{ls}" }
    parsed = ls.strip.split(/[^\S\r]+/).compact
    parsed = parsed.select do |x|
      !x.empty?
    end
    # parsed = ls.strip.split(/[ ]+/)
    Log.debug { "parse_ls parsed: #{parsed}" }
    parsed
  end

  def self.pids_from_ls_proc(ls : Array(String)) : Array(String)
    Log.debug { "pids_from_ls_proc ls: #{ls}" }
    pids = ls.map {|x| "#{x.to_i?}"}.compact
    pids = pids.select do |x|
      !x.empty?
    end
    Log.debug { "pids_from_ls_proc pids: #{pids}" }
    pids
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
    module Node 

      def self.node_by_container_id(container_id)
      end

      def self.node_by_process_name(process_name)
      end

      def self.pids(node)
        Log.info { "pids" }
        ls_proc = ClusterTools.exec_by_node("ls /proc/", node)
        Log.info { "pids ls_proc: #{ls_proc}" }
        parsed_ls = KernelIntrospection.parse_ls(ls_proc[:output])
        pids = KernelIntrospection.pids_from_ls_proc(parsed_ls)
        Log.info { "pids pids: #{pids}" }
        pids
      end

      def self.all_statuses_by_pids(pids : Array(String), node) : Array(String)
        Log.info { "all_statuses_by_pids" }
        proc_statuses = pids.map do |pid|
          proc_status = ClusterTools.exec_by_node("cat /proc/#{pid}/status", node)
          proc_status[:output]
        end

        Log.debug { "proc process_statuses_by_node: #{proc_statuses}" }
        proc_statuses
      end

      def self.status_by_pid(pid, node)
        Log.info { "status_by_pid" }
        status = ClusterTools.exec_by_node("cat /proc/#{pid}/status", node)
        Log.info { "status_by_pid status: #{status}" }
        status[:output]
      end

      def self.cmdline_by_pid(pid : String, node) 
        Log.info { "cmdline_by_pid" }
        cmdline = ClusterTools.exec_by_node("cat /proc/#{pid}/cmdline", node)
        Log.info { "cmdline_by_node cmdline: #{cmdline}" }
        cmdline 
      end

      #todo node_by_name ... in kubetl_client
      #todo use find_first_by_process_name to get pod
      #todo get node_name from pod 
      #todo get node by node_name

      #todo treewalk
      #todo (1) accept pid
      def self.proctree_by_pid(potential_parent_pid, node) : Array(Hash(String, String)) # array of status hashes
        Log.info { "proctree_by_node potential_parent_pid: #{potential_parent_pid}" }
        # proctree = [Hash(String, String).new]
        proctree = [] of Hash(String, String)
        potential_parent_status : Hash(String, String) | Nil = nil
        #todo get next tier
        #todo ls /proc
        # ls_proc = ClusterTools.exec_by_node("ls /proc/", node)
        # Log.info { "proctree_by_node ls_proc: #{ls_proc}" }
        # #todo get all procs that are a number:
        # parsed_ls = KernelIntrospection.parse_ls(ls_proc[:output])
        # pids = KernelIntrospection.pids_from_ls_proc(parsed_ls)
        pids = pids(node)
        Log.info { "proctree_by_pid pids: #{pids}" }
        #  cat /proc/{number}/status 
        proc_statuses = all_statuses_by_pids(pids, node)
        Log.info { "proctree_by_pid proc_statuses: #{proc_statuses}" }
        proc_statuses.each do |proc_status|
          #todo hash out status
          parsed_status = KernelIntrospection.parse_status(proc_status)
          Log.info { "proctree_by_pid parsed_status: #{parsed_status}" }
          #todo get ppid from status
          if parsed_status
            #todo allow for missing Ppid
            ppid = parsed_status["PPid"] 
            current_pid = parsed_status["Pid"] 
            Log.info { "potential_parent_pid, ppid, current_pid #{potential_parent_pid}, #{ppid}, #{current_pid}" }
            # save potential parent pid
            if current_pid == potential_parent_pid 
              cmdline = cmdline_by_pid(current_pid, node)[:output]
              Log.info { "cmdline: #{cmdline}" }
              potential_parent_status = parsed_status.merge({"cmdline" => cmdline}) 
            end
            # Add descendeds of the parent pid
            if ppid == potential_parent_pid && ppid != current_pid
              Log.info { "proctree_by_pid ppid == pid && ppid != current_pid: pid, ppid,
                       current_pid #{potential_parent_pid}, #{ppid}, #{current_pid}" }


              cmdline = cmdline_by_pid(current_pid, node)[:output]
              Log.info { "cmdline: #{cmdline}" }
              parsed_status = parsed_status.merge({"cmdline" => cmdline}) 
              # proctree << parsed_status 
              proctree = proctree + proctree_by_pid(current_pid, node)
            end
          end
        end
        proctree << potential_parent_status if potential_parent_status 
        Log.info { "proctree_by_node final proctree: #{proctree}" }
        Log.info { "proctree_by_node final proctree name pid ppid: #{proctree}" }
        # proctree.each{|x| puts "name: #{x["Name"]}, pid: #{x["Pid"]}, ppid: #{x["PPid"]}"} 
        proctree
      end
    end

    def self.proc(pod_name, container_name, namespace : String | Nil = nil)
      Log.info { "proc namespace: #{namespace}" }
      # todo if container_name nil, dont use container (assume one container)
      resp = KubectlClient.exec("-ti #{pod_name} --container #{container_name} -- ls /proc/", namespace: namespace)
      KernelIntrospection.parse_proc(resp[:output].to_s)
    end

    def self.cmdline(pod_name, container_name, pid, namespace : String | Nil = nil)
      Log.info { "cmdline namespace: #{namespace}" }
      # todo if container_name nil, dont use container (assume one container)
      resp = KubectlClient.exec("-ti #{pod_name} --container #{container_name} -- cat /proc/#{pid}/cmdline", namespace: namespace)
      resp[:output].to_s.strip
    end

    def self.status(pod_name, container_name, pid, namespace : String | Nil = nil)
      # todo if container_name nil, dont use container (assume one container)
      Log.info { "status namespace: #{namespace}" }
      resp = KubectlClient.exec("-ti #{pod_name} --container #{container_name} -- cat /proc/#{pid}/status", namespace: namespace)
      KernelIntrospection.parse_status(resp[:output].to_s)
    end

    def self.status_by_proc(pod_name, container_name, namespace : String | Nil = nil)
      Log.info { "status_by_proc namespace: #{namespace}" }
      proc(pod_name, container_name, namespace).map { |pid|
        stat_cmdline = status(pod_name, container_name, pid, namespace)
        stat_cmdline.merge({"cmdline" => cmdline(pod_name, container_name, pid, namespace)}) if stat_cmdline
      }.compact
    end



    #todo overload with regex
    # def self.find_first_process(process_name) : (Hash(Symbol, Hash(String | Nil, String) | Hash(String, String) | JSON::Any | String) | Nil) 
    def self.find_first_process_using_container(process_name) : (NamedTuple(pod: JSON::Any, 
                                                            container: JSON::Any, 
                                                            status: Hash(String | Nil, String) | Hash(String, String), 
                                                            cmdline: String) | Nil) 
      ret = nil
      pods = KubectlClient::Get.pods
      Log.debug { "Pods: #{pods}" }
      pods["items"].as_a.map do |pod|
        pod_name = pod.dig("metadata", "name")
        generated_name = pod.dig?("metadata", "generateName")
        next if (generated_name == "cluster-tools-" || generated_name == "cluster-tools-k8s-")
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
              # ret = {:pod => pod, :container => container, :status => status, :cmdline => status["cmdline"]}
              ret = {pod: pod, container: container, status: status, cmdline: status["cmdline"]}
              Log.info { "status found: #{ret}" }
              break 
            end
          end
          break if ret
        end
        break if ret
      end
      ret
    end

    #todo separate out run-on-all-nodes concern and pass a block
    def self.find_first_process(process_name) : (NamedTuple(node: JSON::Any,
                                                            pod: JSON::Any, 
                                                            container_status: JSON::Any, 
                                                            # status: Hash(String | Nil, String) | Hash(String, String), 
                                                            status: String, 
                                                            pid: String,
                                                            cmdline: String) | Nil)
      #todo loop through every node
      # cluster_tools = ClusterTools.pod_by_node("#{status["nodeName"]}")
      ret = nil
      nodes = KubectlClient::Get.schedulable_nodes_list
      nodes.map do |node|
        pods = KubectlClient::Get.pods_by_nodes([node])
        # pods["items"].as_a.map do |pod|
        pods.map do |pod|
          status = pod["status"]
          if status["containerStatuses"]?
              container_statuses = status["containerStatuses"].as_a
            Log.debug { "container_statuses: #{container_statuses}" }
            container_statuses.map do |container_status|
              container_id = container_status.dig("containerID").as_s
              #todo get first 13 characters after containerd://
              # short_container_id = container_id.gsub("containerd://", "")[0..13]
              # todo get first answer from array that has a valid response for the id
              # (has the pod/container id on that nodes and is therefore in that 
              # node's proc directory 
              # inspect = ClusterTools.exec_by_node("crictl inspect #{short_container_id}", node)
              # Log.info {"inspect: #{inspect}" }
              # inspect = KubectlClient.exec("#{cluster_tools} -t -- crictl inspect #{id}")
               # next if inspect =~ /rpc error/
              # pid = JSON.parse(inspect[:output]).dig("info", "pid")
              pid = ClusterTools.node_pid_by_container_id(container_id, node)
              # there are some nodes that wont have a proc with this pid in it
              # e.g. a stand alone pod gets installed on only one node
              process = ClusterTools.exec_by_node("cat /proc/#{pid}/cmdline", node)
              Log.info {"cat /proc/#{pid}/cmdline process: #{process[:output]}" }
              # process = KubectlClient.exec("#{cluster_tools} -t -- cat /proc/#{pid}/cmdline ")
              # resp = KubectlClient.exec("-ti #{pod_name} --container #{container_name} -- cat /proc/#{pid}/status", namespace: namespace)
              status = ClusterTools.exec_by_node("cat /proc/#{pid}/status", node)
              Log.info {"status: #{status}" }
              if process[:output] =~ /#{process_name}/
                # todo need to get the proc/status as well
                ret = {node: node, pod: pod, container_status: container_status, status: status[:output], pid: pid.to_s, cmdline: process[:output]}
                Log.info { "status found: #{ret}" }
                break 
              end
            end
          end
          break if ret
        end
        break if ret
      end
      ret
    end
  end
end
