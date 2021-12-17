require "./cluster_utils.cr"
module JaegerManager
  # JAEGER_PORT = "14271" # agent port
  JAEGER_PORT = "14269" # collector port
  def self.uninstall
    Log.for("verbose").info { "uninstall_jaeger" } 
    Helm.delete("jaeger")
  end

  def self.install
    Log.info {"Installing Jaeger daemonset "}
    Helm.helm_repo_add("jaegertracing","https://jaegertracing.github.io/helm-charts")
    Helm.install("jaeger jaegertracing/jaeger ")
    KubectlClient::Get.resource_wait_for_install("Deployment", "jaeger-collector")
    KubectlClient::Get.resource_wait_for_install("Deployment", "jaeger-hotrod")
    KubectlClient::Get.resource_wait_for_install("Deployment", "jaeger-query")
    KubectlClient::Get.resource_wait_for_install("Daemonset", "jaeger-agent")
  end

  def self.node_for_cnf(resource_name)
    KubectlClient.nodes_by_resource(resource)
  end


  def self.jaeger_pods(nodes)
    match = ClusterTools.local_match_by_image_name("jaegertracing/jaeger-collector", nodes)
    # match = Hash{:found => false, :digest => "", :release_name => ""}
    # image_search = "jaegertracing\/jaeger-agent"
    # #todo get name of pod and match against one pod instead of getting all pods and matching them
    # jaeger_tag = KubectlClient::Get.container_tag_from_image_by_nodes(image_search, nodes)
    #
    # if jaeger_tag
    #   Log.info { "jaeger container tag: #{jaeger_tag}" }
    #
    #   pods = KubectlClient::Get.pods_by_nodes(nodes)
    #
    #   # image_name = "jaegertracing/jaeger-agent"
    #   image_name = "jaegertracing/jaeger-collector"
    #   #todo container_digests_by_pod (use pod from previous image search)
    #   imageids = KubectlClient::Get.container_digests_by_nodes(nodes)
    #   resp = ClusterTools.official_content_digest_by_image_name(image_name + ":" + jaeger_tag )
    #   sha_list = [{"name" => image_name, "manifest_digest" => resp["Digest"].as_s}]
    #   Log.info { "jaeger_pods sha_list : #{sha_list}"}
    #   match = DockerClient::K8s.local_digest_match(sha_list, imageids)
    #   Log.info { "match : #{match}"}
    # else
    #   match[:found]=false
    # end
    KubectlClient::Get.pods_by_digest_and_nodes(match[:digest], nodes)
    # if match[:found]
    #   Log.info { "pods_by_node" }
    #   nodes.map { |item|
    #     Log.info { "items labels: #{item.dig?("metadata", "labels")}" }
    #     node_name = item.dig?("metadata", "labels", "kubernetes.io/hostname")
    #     Log.debug { "NodeName: #{node_name}" }
    #     pods = KubectlClient::Get.pods.as_h["items"].as_a.select do |pod| 
    #       found = false
    #       #todo add another pod comparison for sha hash
    #       found = pod["status"]["containerStatuses"].as_a.any? do |container_status|
    #         Log.info { "container_status imageid: #{container_status["imageID"]}"}
    #         Log.info { "match digest: #{match[:digest]}"}
    #         # todo why is this matching multiple pods
    #         match_found = container_status["imageID"].as_s.includes?("#{match[:digest]}")
    #         Log.info { "container_status match_found: #{match_found}"}
    #         match_found
    #       end
    #       Log.info { "found pod: #{pod}"}
    #       pod_name = pod.dig?("metadata", "name")
    #       Log.info { "found PodName: #{pod_name}" }
    #       if found && pod.dig?("spec", "nodeName") == "#{node_name}"
    #         Log.info { "found pod and node: #{pod} #{node_name}" }
    #         true
    #       else
    #         Log.info { "spec node_name: No Match: #{node_name}" }
    #         false
    #       end
    #     end
    #   }.flatten
    # else
    #   Log.info { "match not found: #{match}".colorize(:red) }
    #   [EMPTY_JSON]
    # end
  end

  def self.jaeger_metrics_by_pods(jaeger_pods)
    #todo cluster tools curl call
    Log.info { "jaeger_metrics_by_pods"}
    metrics = jaeger_pods.map do |pod|
      Log.info { "jaeger_metrics_by_pods pod: #{pod}"}
      pod_ips = pod.dig?("status", "podIPs")
      Log.debug { "pod_ips: #{pod_ips}"}
      if pod_ips
        ip_metrics = pod_ips.as_a.map do |ip|
          Log.debug{ "checking: against #{ip.dig("ip").as_s}"}
          msg = metrics_by_pod(ip.dig("ip").as_s)
          Log.debug{ "msg #{msg}"}
          msg
        end
      else
        ip_metrics = ""
      end
      Log.debug { "jaeger_metrics_by_pods ip_metrics: #{ip_metrics}"}
      ip_metrics
    end
    Log.info { "jaeger_metrics_by_pods metrics: #{metrics}"}
    metrics.flatten
  end

  #todo move to prometheus module
  def self.metrics_by_pod(url)
    Log.info { "ClusterTools jaeger metrics" }
    #todo debug this (wrong) ip
    cli = %(curl http://#{url}:#{JAEGER_PORT}/metrics)
    resp = ClusterTools.exec(cli)
    Log.info { "jaeger metrics resp: #{resp[:output]}"}
    resp[:output]
  end

  def self.connected_clients_total
    nodes = KubectlClient::Get.nodes
    pods = jaeger_pods(nodes["items"].as_a)
    metrics = jaeger_metrics_by_pods(pods)
    metrics.reduce(0) do |acc, metric|
      connected_clients = metric.match(/jaeger_agent_client_stats_connected_clients \K[0-9]{1,20}/)
      clients = connected_clients[0] if connected_clients
      if clients
        acc + clients.to_i
      else
        acc
      end

    end
  end

  def self.unique_services_total
    nodes = KubectlClient::Get.nodes
    pods = jaeger_pods(nodes["items"].as_a)
    metrics = jaeger_metrics_by_pods(pods)
    metrics.reduce(0) do |acc, metric|
      unique_services = metric.match(/jaeger_agent_client_stats_connected_clients \K[0-9]{1,20}/)
      unique_services = metric.split("/n").reduce(0){|acc, f| c = (f =~ /jaeger_collector_spans_saved_by_svc_total{debug=".*",result=".*",svc="(?!other-services).*}/) ; c ? acc + 1 : acc }
      if unique_services 
        acc + unique_services 
      else
        acc
      end
    end
  end

  def self.tracing_used?(baseline, cnf_count)
    cnf_count != baseline
  end

end

