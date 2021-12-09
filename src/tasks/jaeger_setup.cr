require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Install Jaeger"
task "install_jaeger" do |_, args|
  JaegerManager.install
end

desc "Uninstall Jaeger"
task "uninstall_jaeger" do |_, args|
  JaegerManager.uninstall
end

module JaegerManager
  JAEGER_PORT = "14271"
  def self.uninstall
    Log.for("verbose").info { "uninstall_jaeger" } 
    Helm.delete("jaeger")
  end

  def self.install
    Log.info {"Installing Jaeger daemonset "}
    Helm.helm_repo_add("jaegertracing","https://jaegertracing.github.io/helm-charts")
    Helm.install("--set hotrod.enabled=true jaeger jaegertracing/jaeger ")
    KubectlClient::Get.resource_wait_for_install("Deployment", "jaeger-collector")
    KubectlClient::Get.resource_wait_for_install("Deployment", "jaeger-hotrod")
    KubectlClient::Get.resource_wait_for_install("Deployment", "jaeger-query")
    KubectlClient::Get.resource_wait_for_install("Daemonset", "jaeger-agent")
  end

  # todo get node for cnf
  # todo get pod for jaeger agent that is on that node
  # todo ip for jaeger agent pod 
  # todo call /metrics on agent pod
  # todo check /metrics on agent
  # todo get a baseline:
  # todo use regex metrics log for batches recieved total
  # todo use regex metrics log for connected clients total 
  # todo install cnf:
  # todo (optional) use regex metrics log for batches recieved total
  # todo use regex metrics log for connected clients total 
  # todo compare baseline with installed cnf metrics

  # 
  # def self.batches_recieved_total
  # end

  def self.node_for_cnf(resource_name)
    KubectlClient.nodes_by_resource(resource)
  end


  def self.jaeger_pods(nodes)
    pods = KubectlClient::Get.pods_by_nodes(nodes)
    #todo sha hash
    # page = 1
    match = Hash{:found => false, :digest => "", :release_name => ""}
    # match = {:found => false}
    imageids = KubectlClient::Get.container_digests_by_nodes(nodes)
    # while match[:found]==false && page < 3 
      # Log.info { "page: #{page}".colorize(:yellow)}
      image_name = "jaegertracing/jaeger-agent"
      tags = DockerClient::Get.image_tags(image_name)
      Log.info { "jaeger_pods tags : #{tags}"}
      # sha_list : Array(JSON::Any) = [] of JSON::Any
      # sha_list = tags.each do | tag|
      #   resp = ClusterTools.official_content_digest_by_image_name(image_name + ":" + tag)
      #   resp["Digest"]
      # end
      sha_list = tags.not_nil!.reduce([] of Hash(String, String)) do |acc, i|
        resp = ClusterTools.official_content_digest_by_image_name(image_name + ":" + i["name"])
        acc << {"name" => image_name, "manifest_digest" => resp["Digest"].as_s}
      end
      # resp = Halite.get("https://hub.docker.com/v2/repositories/jaegertracing/jaeger-agent/tags?page=#{page}&page_size=100", 
      #                   headers: {"Authorization" => "JWT"})
      # #todo get all tags
      # #todo call cluster tools
      # docker_resp = resp.body
      # Log.debug { "docker_resp: #{docker_resp}" }
      # sha_list = named_sha_list(docker_resp)
      match = DockerClient::K8s.local_digest_match(sha_list, imageids)
    #   page = page + 1
    # end
    Log.info { "match : #{match}"}
    if match[:found]
      # todo get pod by container digest by node
      # nodes = KubectlClient::Get.resource_select(KubectlClient::Get.nodes) do |item, metadata|
      #   taints = item.dig?("spec", "taints")
      #   Log.debug { "taints: #{taints}" }
      #   if (taints && taints.as_a.find{ |x| x.dig?("effect") == "NoSchedule" })
      #     # EMPTY_JSON 
      #     false 
      #   else
      #     # item
      #     true
      #   end
      # end
      Log.info { "pods_by_node" }
      nodes.map { |item|
        Log.info { "items labels: #{item.dig?("metadata", "labels")}" }
        node_name = item.dig?("metadata", "labels", "kubernetes.io/hostname")
        Log.debug { "NodeName: #{node_name}" }
        pods = KubectlClient::Get.pods.as_h["items"].as_a.select do |pod| 
          found = false
          #todo add another pod comparison for sha hash
          found = pod["status"]["containerStatuses"].as_a.select do |container_status|
            Log.info { "container_status imageid: #{container_status["imageID"]}"}
            Log.info { "match digest: #{match[:digest]}"
            container_status["imageID"].as_s.includes?("#{match[:digest]}")}
          end
          if pod.dig?("spec", "nodeName") == "#{node_name}" && found
            Log.info { "pod: #{pod}" }
            pod_name = pod.dig?("metadata", "name")
            Log.info { "PodName: #{pod_name}" }
            true
          else
            Log.info { "spec node_name: No Match: #{node_name}" }
            false
          end
        end
      }.flatten
    else
      Log.info { "match not found: #{match}".colorize(:red) }
      [EMPTY_JSON]
    end
  end
  # #todo create hash to map nodes with jaeger pods
  # def self.pods_by_nodes(nodes_json : Array(JSON::Any))
  #   Log.info { "pods_by_node" }
  #   nodes_json.map { |item|
  #     Log.info { "items labels: #{item.dig?("metadata", "labels")}" }
  #     node_name = item.dig?("metadata", "labels", "kubernetes.io/hostname")
  #     Log.debug { "NodeName: #{node_name}" }
  #   }
  #
  #   pods.select do |pod|
  #     if pod.dig?("metadata", "name") == "jaeger"
  #       true
  #     else
  #       false
  #     end
  #   end
  # end

  def self.jaeger_metrics_by_pods(jaeger_pods)
    #todo cluster tools curl call
    Log.info { "jaeger_metrics_by_pods"}
    jaeger_pods.each do |pod|
      Log.info { "jaeger_metrics_by_pods pod: #{pod}"}
      pod_ips = pod.dig("status", "podIPs")
      Log.info { "pod_ips: #{pod_ips}"}
      pod_ips.as_a.each do |ip|
        Log.info { "checking: against #{ip.dig("ip").as_s}"}
        msg = metrics_by_pod(ip.dig("ip").as_s)
      end
    end
  end

  #todo move to prometheus module
  def self.metrics_by_pod(url)
    Log.info { "ClusterTools jaeger metrics" }
    #todo debug this (wrong) ip
    cli = %(curl http://#{url}:#{JAEGER_PORT}/metrics)
    resp = ClusterTools.exec(cli)
    Log.info { "jaeger metrics resp: #{resp}"}
    resp
  end

  def self.connected_clients_total(resource_name)
    node = node_for_cnf(resource_name)
    pod = jaeger_pod(node)
    metrics = jaeger_metrics(pod)
    connected_clients = metrics.match(/jaeger_agent_client_stats_connected_clients \K[0-9]{1,20}/)
    connected_clients[0]
  end

  def self.tracing_used?(baseline, cnf_count)
    cnf_count != baseline
  end

end

