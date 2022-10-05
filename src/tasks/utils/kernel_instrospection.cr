require "colorize"
require "kubectl_client"

module KernelIntrospection
  def self.os_release
      Log.info { "KernelIntrospection.os_release" }
    # todo use silent call out
    # os_release = `cat /etc/os-release`
    Process.run(
      # "sudo chmod +x ./clusterctl",
         "cat /etc/os-release",
      shell: true,
      output: stdout = IO::Memory.new,
      error: stderr = IO::Memory.new
    )
    os_release = stdout.to_s
    Log.debug { "os-release: #{os_release}" }
    multiline_os_release = os_release.split("\n")
    parsed_os_release = multiline_os_release.reduce(Hash(String, String).new) do |acc,x|  
      if x.empty? 
        acc 
      else
       acc.merge({"#{x.split("=")[0]}" =>"#{x.split("=")[1]}"})
      end
    end

    if parsed_os_release == Hash(String, String).new
      nil
    else
      parsed_os_release
    end
  end

  def self.os_release_id
    Log.info { "KernelIntrospection.os_release_id" }
    osr = os_release
    if osr 
     id = osr["ID"]
    else
     id =  nil
    end
    Log.info { "os_release: #{osr}" }
    Log.info { "release_id: #{id}" }
    id
  end

  def self.parse_proc(ps_output)
    ps_output.split("\n").map{|x| x.to_i?}.compact
  end

  def self.parse_status(status_output : String) : (Hash(String, String) | Nil) 
    Log.debug { "parse_status status_output: #{status_output}" }
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
          Log.info { "all_statuses_by_pids pid: #{pid}" }
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


      def self.verify_single_proc_tree(original_parent_pid, name, proctree : Array(Hash(String, String)))
        Log.info { "verify_single_proc_tree pid, name: #{original_parent_pid}, #{name}" }
        verified = true 
        proctree.map do | pt |
          current_pid = "#{pt["Pid"]}".strip
          ppid = "#{pt["PPid"]}".strip
          status_name = "#{pt["Name"]}".strip

          if current_pid == original_parent_pid && ppid != "" && 
            status_name != name
            # todo exclude tini, init, dumbinit?, from violations
            Log.info { "top level parent (i.e. superviser -- first parent with different name): #{status_name}" }
            verified = false

          elsif current_pid == original_parent_pid && ppid != "" && 
            status_name == name

            verified = verify_single_proc_tree(ppid, name, proctree)
          end
        end
        Log.info { "verified?: #{verified}" }
        verified
      end

      def self.proctree_by_pid(potential_parent_pid : String, node : JSON::Any, proc_statuses : (Array(String) | Nil)  = nil) : Array(Hash(String, String)) # array of status hashes
        Log.info { "proctree_by_node potential_parent_pid: #{potential_parent_pid}" }
        proctree = [] of Hash(String, String)
        potential_parent_status : Hash(String, String) | Nil = nil
        unless proc_statuses
          pids = pids(node) 
          Log.info { "proctree_by_pid pids: #{pids}" }
          proc_statuses = all_statuses_by_pids(pids, node)
        end
        Log.debug { "proctree_by_pid proc_statuses: #{proc_statuses}" }
        proc_statuses.each do |proc_status|
          parsed_status = KernelIntrospection.parse_status(proc_status)
          Log.debug { "proctree_by_pid parsed_status: #{parsed_status}" }
          if parsed_status
            ppid = parsed_status["PPid"].strip 
            current_pid = parsed_status["Pid"].strip
            Log.info { "potential_parent_pid, ppid, current_pid #{potential_parent_pid}, #{ppid}, #{current_pid}" }
            # save potential parent pid
            if current_pid == potential_parent_pid
              Log.info { "current_pid == potential_parent_pid" }
              cmdline = cmdline_by_pid(current_pid, node)[:output]
              Log.info { "cmdline: #{cmdline}" }
              potential_parent_status = parsed_status.merge({"cmdline" => cmdline}) 
              proctree << potential_parent_status 
            # Add descendeds of the parent pid
            elsif ppid == potential_parent_pid && ppid != current_pid
              Log.info { "ppid == potential_parent_pid" }
              Log.info { "proctree_by_pid ppid == pid && ppid != current_pid: pid, ppid,
                       current_pid #{potential_parent_pid}, #{ppid}, #{current_pid}" }


              cmdline = cmdline_by_pid(current_pid, node)[:output]
              Log.info { " the matched descendent is cmdline: #{cmdline}" }
              proctree = proctree + proctree_by_pid(current_pid, node, proc_statuses)
            end
          end
        end
        Log.info { "proctree_by_node final proctree: #{proctree}" }
        proctree.each{|x| Log.info { "Process name: #{x["Name"]}, pid: #{x["Pid"]}, ppid: #{x["PPid"]}" } }
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


    alias MatchingProcessInfo = NamedTuple(
      node: JSON::Any,
      pod: JSON::Any,
      container_status: JSON::Any, 
      status: String,
      pid: String,
      cmdline: String
    )

    # #todo overload with regex
    def self.find_first_process(process_name) : (MatchingProcessInfo | Nil)
      Log.info { "find_first_process" }
      ret = nil
      nodes = KubectlClient::Get.schedulable_nodes_list
      nodes.map do |node|
        pods = KubectlClient::Get.pods_by_nodes([node])
        pods.map do |pod|
          status = pod["status"]
          if status["containerStatuses"]?
              container_statuses = status["containerStatuses"].as_a
            Log.debug { "container_statuses: #{container_statuses}" }
            container_statuses.map do |container_status|
              ready = container_status.dig("ready").as_bool
              next unless ready
              container_id = container_status.dig("containerID").as_s
              pid = ClusterTools.node_pid_by_container_id(container_id, node)
              # there are some nodes that wont have a proc with this pid in it
              # e.g. a stand alone pod gets installed on only one node
              process = ClusterTools.exec_by_node("cat /proc/#{pid}/cmdline", node)
              Log.info {"cat /proc/#{pid}/cmdline process: #{process[:output]}" }
              status = ClusterTools.exec_by_node("cat /proc/#{pid}/status", node)
              Log.info {"status: #{status}" }
              if process[:output] =~ /#{process_name}/
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


    def self.find_matching_processes(process_name) : Array(MatchingProcessInfo)
      Log.info { "find_first_process" }
      results = [] of MatchingProcessInfo
      nodes = KubectlClient::Get.schedulable_nodes_list
      nodes.map do |node|
        pods = KubectlClient::Get.pods_by_nodes([node])
        pods.map do |pod|
          status = pod["status"]
          if status["containerStatuses"]?
            container_statuses = status["containerStatuses"].as_a
            Log.debug { "container_statuses: #{container_statuses}" }
            container_statuses.map do |container_status|
              ready = container_status.dig("ready").as_bool
              next unless ready
              container_id = container_status.dig("containerID").as_s
              pid = ClusterTools.node_pid_by_container_id(container_id, node)
              # there are some nodes that wont have a proc with this pid in it
              # e.g. a stand alone pod gets installed on only one node
              process = ClusterTools.exec_by_node("cat /proc/#{pid}/cmdline", node)
              Log.info {"cat /proc/#{pid}/cmdline process: #{process[:output]}" }
              status = ClusterTools.exec_by_node("cat /proc/#{pid}/status", node)
              Log.info {"status: #{status}" }
              if process[:output] =~ /#{process_name}/
                result = {node: node, pod: pod, container_status: container_status, status: status[:output], pid: pid.to_s, cmdline: process[:output]}
                results.push(result)
                Log.for("find_matching_processes").info { "status found: #{result}" }
                # break 
              end
            end
          end
          # break if ret
        end
        # break if ret
      end
      results
    end

  end
end
