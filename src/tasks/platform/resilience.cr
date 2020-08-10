# coding: utf-8
require "sam"
require "colorize"
require "../utils/utils.cr"

namespace "platform" do
  desc "The CNF conformance suite checks to see if the CNFs are resilient to failures."
  task "resilience", ["node_failure"] do |t, args|
    VERBOSE_LOGGING.info "resilience" if check_verbose(args)
    VERBOSE_LOGGING.debug "resilience args.raw: #{args.raw}" if check_verbose(args)
    VERBOSE_LOGGING.debug "resilience args.named: #{args.named}" if check_verbose(args)
    stdout_score("resilience")
  end

  desc "Does the Platform recover the node and reschedule pods when a worker node fails"
  task "node_failure" do |_, args|
    unless check_poc(args)
      LOGGING.info "skipping node_failure"
      puts "Skipped".colorize(:yellow)
      next
    end
    LOGGING.info "Running POC"
    task_response = task_runner(args) do |args|
      current_dir = FileUtils.pwd 
      helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"

      #Select the first node that isn't a master and is also schedulable
      worker_nodes = `kubectl get nodes --selector='!node-role.kubernetes.io/master' -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ "\\n"}}{{end}}{{end}}'`
      worker_node = worker_nodes.split("\n")[0]

      install_coredns = `#{helm} install node-failure --set nodeSelector."kubernetes\\.io/hostname"=#{worker_node} /home/pair/src/denver/cnf-conformance/coredns/coredns`
      wait_for_install("node-failure-coredns")


      File.write("reboot_daemon_pod.yml", REBOOT_DAEMON)
      install_reboot_daemon = `kubectl create -f reboot_daemon_pod.yml`

      # Find Reboot Daemon name
      reboot_daemon_pod = pod_status("reboot", "--field-selector spec.nodeName=#{worker_node}").split(",")[0]
      start_reboot = `kubectl exec -ti #{reboot_daemon_pod} touch /tmp/reboot`
      status = node_status("#{worker_node}")

      #Watch for Node Failure.
      pod_ready = ""
      node_ready = ""
      until (pod_ready == "false" || node_ready == "False" || node_ready == "Unknown")
        pod_ready = pod_status("node-failure").split(",")[2]
        node_ready = node_status("#{worker_node}")
        puts "Pod Ready Status: #{pod_ready}"
        puts "Node Ready Status: #{node_ready}"
        sleep 0.1
      end

      #Watch for Node to come back online
      pod_ready = ""
      node_ready = ""
      until (pod_ready == "true" && node_ready == "True")
        pod_ready = pod_status("node-failure", "").split(",")[2]
        node_ready = node_status("#{worker_node}")
        puts "Pod Ready Status: #{pod_ready}"
        puts "Node Ready Status: #{node_ready}"
        sleep 0.1
      end
      puts "Debug"



      # emoji_chaos_network_loss="📶☠️"
      # resp = upsert_passed_task("node_failure","✔️  PASSED: Nodes are resilient #{emoji_chaos_network_loss}")

      File.delete("reboot_daemon_pod.yml")
    end
  end
end
