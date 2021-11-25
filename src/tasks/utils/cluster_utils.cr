module ClusterTools
  def self.install
    Log.info { "ClusterTools install" }
    File.write("cluster_tools.yml", CLUSTER_TOOLS)
    KubectlClient::Apply.file("cluster_tools.yml")
    wait_for_cluster_tools
  end
  def self.uninstall
    Log.info { "ClusterTools uninstall" }
    KubectlClient::Delete.file("cluster_tools.yml")
  end
  def self.exec(cli, namespace="default")
    Log.info { "ClusterTools exec partial cli: #{cli}" }
    # todo cluster_tools_exec command
    # todo change to get all pods, schedulable nodes is slow
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cluster-tools")

    # File.write("cluster_tools.yml", CLUSTER_TOOLS)
    # KubectlClient::Apply.file("cluster_tools.yml")

    # KubectlClient::Get.wait_for_cluster_tools
    cluster_tools_pod_name = pods[0].dig?("metadata", "name") if pods[0]?
    Log.info { "cluster_tools_pod_name: #{cluster_tools_pod_name}"}
    full_cli = "--namespace=#{namespace} -ti #{cluster_tools_pod_name} -- #{cli}"
    Log.info { "ClusterTools exec full cli: #{full_cli}" }
    resp = KubectlClient.exec(full_cli)  
    resp
  end

  def self.wait_for_cluster_tools(wait_count : Int32 = 10)
    Log.info { "ClusterTools wait_for_cluster_tools" }
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cluster-tools")
    ready = false
    timeout = wait_count
    # cluster tools doesn't have a real readiness check ... mimicing one
    `touch /tmp/testfile`
    pods.map do |pod| 
      until (ready == true || timeout <= 0) 
        sh = KubectlClient.cp("/tmp/testfile #{pod.dig?("metadata", "name")}:/tmp/test")
        if sh[:status].success?
          ready = true
        end
        sleep 1
        timeout = timeout - 1 
        LOGGING.info "Waiting for Cluster-Tools Pod"
      end
      if timeout <= 0
        break
      end
    end
  end
  def self.open_metric_validator(url)
    Log.info { "ClusterTools open_metric_validator" }
    cli = %(/bin/bash -c "curl #{url} | openmetricsvalidator")
    resp = exec(cli)
    Log.info { "metrics resp: #{resp}"}
    resp
  end
end
