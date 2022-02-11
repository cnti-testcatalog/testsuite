module ClusterTools
  def self.install
    Log.info { "ClusterTools install" }
    File.write("cluster_tools.yml", CLUSTER_TOOLS)
    KubectlClient::Apply.file("cluster_tools.yml", namespace: TESTSUITE_NAMESPACE)
    wait_for_cluster_tools
  end
  def self.uninstall
    Log.info { "ClusterTools uninstall" }
    File.write("cluster_tools.yml", CLUSTER_TOOLS)
    KubectlClient::Delete.file("cluster_tools.yml", namespace: TESTSUITE_NAMESPACE)
    KubectlClient::Get.resource_wait_for_uninstall("Daemonset", "cluster-tools", namespace: TESTSUITE_NAMESPACE)
  end

  def self.exec(cli : String)
    # todo change to get all pods, schedulable nodes is slow
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cluster-tools")

    cluster_tools_pod_name = pods[0].dig?("metadata", "name") if pods[0]?
    Log.info { "cluster_tools_pod_name: #{cluster_tools_pod_name}"}

    cmd = "-ti #{cluster_tools_pod_name} -- #{cli}"
    KubectlClient.exec(cmd, namespace: TESTSUITE_NAMESPACE)
  end

  def self.exec_k8s(cli : String)
    # todo change to get all pods, schedulable nodes is slow

    # pods_by_nodes internally use KubectlClient::Get.pods which uses --all-namespaces option.
    # So they do not have to be passed the namespace to perform operations.
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cluster-tools-k8s")

    cluster_tools_pod_name = pods[0].dig?("metadata", "name") if pods[0]?
    Log.info { "cluster_tools_pod_name: #{cluster_tools_pod_name}"}

    full_cli = "-ti #{cluster_tools_pod_name} -- #{cli}"
    Log.info { "ClusterTools exec full cli: #{full_cli}" }
    KubectlClient.exec(full_cli, namespace: TESTSUITE_NAMESPACE)
  end

  def self.wait_for_cluster_tools
    Log.info { "ClusterTools wait_for_cluster_tools" }
    KubectlClient::Get.resource_wait_for_install("Daemonset", "cluster-tools", namespace: TESTSUITE_NAMESPACE)
    KubectlClient::Get.resource_wait_for_install("Daemonset", "cluster-tools-k8s", namespace: TESTSUITE_NAMESPACE)
  end

  # https://windsock.io/explaining-docker-image-ids/
  # works on dockerhub and quay!
  # ex. kubectl exec -ti cluster-tools-ww9lg -- skopeo inspect docker://jaegertracing/jaeger-agent:1.28.0
  # Accepts org/image:tag or repo/org/image:tag
  # A content digest is an uncompressed digest, which is what Kubernetes tracks 
  def self.official_content_digest_by_image_name(image_name)
    Log.info { "official_content_digest_by_image_name: #{image_name}"}

    result = exec("skopeo inspect docker://#{image_name}")
    response = result[:output]
    if result[:status].success? && !response.empty?
      return JSON.parse(response)
    end
    JSON.parse(%({}))
  end

  def self.local_match_by_image_name(image_name, nodes=KubectlClient::Get.nodes["items"].as_a )
    Log.info { "local_match_by_image_name image_name: #{image_name}" }
    match = Hash{:found => false, :digest => "", :release_name => ""}
    #todo get name of pod and match against one pod instead of getting all pods and matching them
    tag = KubectlClient::Get.container_tag_from_image_by_nodes(image_name, nodes)

    if tag
      Log.info { "container tag: #{tag}" }

      pods = KubectlClient::Get.pods_by_nodes(nodes)

      #todo container_digests_by_pod (use pod from previous image search) --- performance enhancement
      imageids = KubectlClient::Get.container_digests_by_nodes(nodes)
      resp = ClusterTools.official_content_digest_by_image_name(image_name + ":" + tag )
      sha_list = [{"name" => image_name, "manifest_digest" => resp["Digest"].as_s}]
      Log.info { "jaeger_pods sha_list : #{sha_list}"}
      match = DockerClient::K8s.local_digest_match(sha_list, imageids)
      Log.info { "match : #{match}"}
    else
      match[:found]=false
    end
    Log.info { "local_match_by_image_name match: #{match}" }
    match
  end

  def self.pod_name()
    KubectlClient::Get.pod_status("cluster-tools").split(",")[0]
  end

  def self.pod_by_node(node)
    resource = KubectlClient::Get.resource("Daemonset", "cluster-tools", namespace: TESTSUITE_NAMESPACE)
    pods = KubectlClient::Get.pods_by_resource(resource)
    cluster_pod = pods.find do |pod|
      pod.dig("spec", "nodeName") == node
    end
    cluster_pod.dig("metadata", "name") if cluster_pod
  end
end
