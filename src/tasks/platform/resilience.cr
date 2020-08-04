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

      #Select the first node that isn't a master and is also schedulable
      worker_nodes = `kubectl get nodes --selector='!node-role.kubernetes.io/master' -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ "\\n"}}{{end}}{{end}}'`
      worker_node = worker_nodes.split("\n")[0]

      # install_coredns = `helm install node_failure --set nodeSelector."kubernetes\\.io/hostname"=#{worker_node} stable/coredns`

      pod_status("test-coredns")
      # `kubectl exec -ti reboot touch /tmp/reboot`

      # emoji_chaos_network_loss="📶☠️"
      # resp = upsert_passed_task("node_failure","✔️  PASSED: Nodes are resilient #{emoji_chaos_network_loss}")
    end
  end
end
