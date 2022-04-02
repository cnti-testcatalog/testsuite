# coding: utf-8
require "sam"
require "colorize"
require "../utils/utils.cr"
require "retriable"

namespace "platform" do
  desc "The CNF test suite checks to see if the Platform has Observability support."
  task "observability", ["kube_state_metrics", "node_exporter", "prometheus_adapter", "metrics_server"] do |t, args|
    Log.for("verbose").info { "observability" } if check_verbose(args)
    Log.for("verbose").debug { "observability args.raw: #{args.raw}" } if check_verbose(args)
    Log.for("verbose").debug { "observability args.named: #{args.named}" } if check_verbose(args)
    stdout_score("platform:observability")
  end

  desc "Does the Platform have Kube State Metrics installed"
  task "kube_state_metrics" do |_, args|
    unless check_poc(args)
      Log.info { "skipping kube_state_metrics: not in poc mode" }
      puts "SKIPPED: Kube State Metrics".colorize(:yellow)
      next
    end
    if args.named["offline"]?
      Log.info { "skipping kube_state_metrics: in offline mode" }
      puts "SKIPPED: Kube State Metrics".colorize(:yellow)
      next
    end
    Log.info { "Running POC: kube_state_metrics" }
    Retriable.retry do
      task_response = CNFManager::Task.task_runner(args) do |args|
        current_dir = FileUtils.pwd

        # state_metric_releases is available at the url below
        # curl -L -s https://quay.io/api/v1/repository/coreos/kube-state-metrics/tag/?limit=100
        resp = Halite.get("https://quay.io/api/v1/repository/coreos/kube-state-metrics/tag/?limit=100")
        state_metric_releases = resp.body

        # Get the sha hash for the kube-state-metrics container
        sha_list = named_sha_list(state_metric_releases)
        Log.debug { "sha_list: #{sha_list}" }

        # find hash for image
        imageids = KubectlClient::Get.all_container_repo_digests
        Log.debug { "imageids: #{imageids}" }
        found = false
        release_name = ""
        sha_list.each do |x|
          if imageids.find{|i| i.includes?(x["manifest_digest"])}
            found = true
            release_name = x["name"]
          end
        end
        if found
          emoji_kube_state_metrics="📶☠️"
          upsert_passed_task("kube_state_metrics","✔️  PASSED: Your platform is using the #{release_name} release for kube state metrics #{emoji_kube_state_metrics}")
        else
          emoji_kube_state_metrics="📶☠️"
          upsert_failed_task("kube_state_metrics", "✖️  FAILED: Your platform does not have kube state metrics installed #{emoji_kube_state_metrics}")
        end
      end
    end
  end

  desc "Does the Platform have a Node Exporter installed"
  task "node_exporter" do |_, args|
    unless check_poc(args)
      Log.info { "skipping node_exporter: not in poc mode" }
      puts "SKIPPED: Node Exporter".colorize(:yellow)
      next
    end

    unless check_containerd
      Log.info { "skipping node_exporter: This test only supports the Containerd Runtime." }
      puts "SKIPPED: Node Exporter".colorize(:yellow)
      next
    end

    if args.named["offline"]?
      Log.info { "skipping node_exporter: in offline mode" }
      puts "SKIPPED: Node Exporter".colorize(:yellow)
      next
    end
    Log.info { "Running POC: node_exporter" }
    Retriable.retry do
      task_response = CNFManager::Task.task_runner(args) do |args|
        #Select the first node that isn't a master and is also schedulable
        #worker_nodes = `kubectl get nodes --selector='!node-role.kubernetes.io/master' -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ "\\n"}}{{end}}{{end}}'`
        #worker_node = worker_nodes.split("\n")[0]

        ClusterTools.install
        cluster_tools_pod = ClusterTools.pod_name
        Log.debug { "cluster_tools_pod: #{cluster_tools_pod}" }

        # Fetch id sha256 sums for all repo_digests https://github.com/docker/distribution/issues/1662
        repo_digest_list = KubectlClient::Get.all_container_repo_digests
        Log.info { "container_repo_digests: #{repo_digest_list}" }
        id_sha256_list = repo_digest_list.reduce([] of String) do |acc, repo_digest|
          Log.info { "repo_digest: #{repo_digest}" }
          resp = KubectlClient.exec("#{ClusterTools.pod_name} -- crictl inspecti #{repo_digest}", namespace: TESTSUITE_NAMESPACE)
          cricti = resp[:output].to_s
          begin
            parsed_json = JSON.parse(cricti)
            acc << parsed_json["status"]["id"].as_s
          rescue
            Log.error { "cricti not valid json: #{cricti}" }
            acc
          end
        end
        Log.debug { "id_sha256_list: #{id_sha256_list}" }


        # Fetch image id sha256sums available for all upstream node-exporter releases
        #
        # node_exporter_releases is available at the url below
        #
        # curl -L -s 'https://registry.hub.docker.com/v2/repositories/prom/node-exporter/tags?page_size=1024'
        resp = Halite.get("https://registry.hub.docker.com/v2/repositories/prom/node-exporter/tags?page_size=1024")
        node_exporter_releases = resp.body

        tag_list = named_sha_list(node_exporter_releases)
        Log.info { "tag_list: #{tag_list}" }
        if ENV["DOCKERHUB_USERNAME"]? && ENV["DOCKERHUB_PASSWORD"]?
            target_ns_repo = "prom/node-exporter"
          params = "service=registry.docker.io&scope=repository:#{target_ns_repo}:pull"

          # token is available at the url below
          #
          # curl "https://auth.docker.io/token?#{params}" \
          #      --user "#{ENV["DOCKERHUB_USERNAME"]}:#{ENV["DOCKERHUB_PASSWORD"]}"
          resp = Halite.basic_auth(user: ENV["DOCKERHUB_USERNAME"], pass: ENV["DOCKERHUB_PASSWORD"]).
            get("https://auth.docker.io/token?#{params}")
          token = resp.body
          Log.debug { "token: #{token}" }

          if token =~ /incorrect username/
            Log.error { "error: #{token}" }
          end
          parsed_token = JSON.parse(token)
          release_id_list = tag_list.reduce([] of Hash(String, String)) do |acc, tag|
            Log.info { "tag: #{tag}" }
            tag = tag["name"]

            # image_id is available at the url below
            #
            # curl "https://registry-1.docker.io/v2/#{target_ns_repo}/manifests/#{tag}" \
            #      -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
            #      -H "Authorization:Bearer #{parsed_token["token"].as_s}"
            resp = Halite.auth(
              "Bearer #{parsed_token["token"].as_s}"
            ).get(
              "https://registry-1.docker.io/v2/#{target_ns_repo}/manifests/#{tag}",
              headers: {Accept: "application/vnd.docker.distribution.manifest.v2+json"}
            )
            image_id = resp.body

            Log.info { "Image ID #{image_id}" }

            parsed_image = JSON.parse(image_id)
            Log.info { "parsed_image config digest #{parsed_image["config"]["digest"]}" }
            if parsed_image["config"]["digest"]?
                acc << {"name" => tag, "digest"=> parsed_image["config"]["digest"].as_s}
            else
              acc
            end
          end
        else
          puts "DOCKERHUB_USERNAME & DOCKERHUB_PASSWORD Must be set."
          exit 1
        end
        Log.info { "Release id sha256sum list: #{release_id_list}" }

        found = false
        release_name = ""
        release_id_list.each do |x|
          if id_sha256_list.find{|i| i.includes?(x["digest"])}
            found = true
            release_name = x["name"]
          end
        end
        if found
          emoji_node_exporter="📶☠️"
          upsert_passed_task("node_exporter","✔️  PASSED: Your platform is using the #{release_name} release for the node exporter #{emoji_node_exporter}")
        else
          emoji_node_exporter="📶☠️"
          upsert_failed_task("node_exporter", "✖️  FAILED: Your platform does not have the node exporter installed #{emoji_node_exporter}")
        end
      end
    end
  end
end


  desc "Does the Platform have the prometheus adapter installed"
  task "prometheus_adapter" do |_, args|
    unless check_poc(args)
      Log.info { "skipping prometheus_adapter: not in poc mode" }
      puts "SKIPPED: Prometheus Adapter".colorize(:yellow)
      next
    end
    if args.named["offline"]?
      Log.info { "skipping prometheus_adapter: in offline mode" }
      puts "SKIPPED: Prometheus Adapter".colorize(:yellow)
      next
    end
    Log.info { "Running POC: prometheus_adapter" }
    Retriable.retry do
      task_response = CNFManager::Task.task_runner(args) do |args|
        # Fetch image id sha256sums available for all upstream prometheus_adapter releases
        # prometheus_adapter_releases is available at the url below
        # curl -L -s 'https://registry.hub.docker.com/v2/repositories/directxman12/k8s-prometheus-adapter-amd64/tags?page_size=1024'
        resp = Halite.get("https://registry.hub.docker.com/v2/repositories/directxman12/k8s-prometheus-adapter-amd64/tags?page_size=1024")
        prometheus_adapter_releases = resp.body
        sha_list = named_sha_list(prometheus_adapter_releases)
        Log.debug { "sha_list: #{sha_list}" }

        # find hash for image
        imageids = KubectlClient::Get.all_container_repo_digests
        Log.debug { "imageids: #{imageids}" }
        found = false
        release_name = ""
        sha_list.each do |x|
          if imageids.find{|i| i.includes?(x["manifest_digest"])}
            found = true
            release_name = x["name"]
          end
        end

        if found
          emoji_prometheus_adapter="📶☠️"
          upsert_passed_task("prometheus_adapter","✔️  PASSED: Your platform is using the #{release_name} release for the prometheus adapter #{emoji_prometheus_adapter}")
        else
          emoji_prometheus_adapter="📶☠️"
          upsert_failed_task("prometheus_adapter", "✖️  FAILED: Your platform does not have the prometheus adapter installed #{emoji_prometheus_adapter}")
        end
      end
    end
  end

  desc "Does the Platform have the K8s Metrics Server installed"
  task "metrics_server" do |_, args|
    unless check_poc(args)
      Log.info { "skipping metrics_server: not in poc mode" }
      puts "SKIPPED: Metrics Server".colorize(:yellow)
      next
    end
    if args.named["offline"]?
      Log.info { "skipping metrics_server: in offline mode" }
      puts "SKIPPED: Metrics Server".colorize(:yellow)
      next
    end
    Log.info { "Running POC: metrics_server" }
    Retriable.retry do
      task_response = CNFManager::Task.task_runner(args) do |args|

        #Select the first node that isn't a master and is also schedulable
        #worker_nodes = `kubectl get nodes --selector='!node-role.kubernetes.io/master' -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ "\\n"}}{{end}}{{end}}'`
        #worker_node = worker_nodes.split("\n")[0]

        # Install and find CRI Tools name
        ClusterTools.install
        cluster_tools_pod = ClusterTools.pod_name
        Log.debug { "cluster_tools_pod: #{cluster_tools_pod}" }

        # Fetch id sha256 sums for all repo_digests https://github.com/docker/distribution/issues/1662
        repo_digest_list = KubectlClient::Get.all_container_repo_digests
        Log.info { "container_repo_digests: #{repo_digest_list}" }
        id_sha256_list = repo_digest_list.reduce([] of String) do |acc, repo_digest|
          Log.debug { "repo_digest: #{repo_digest}" }
          cricti = KubectlClient.exec("-ti #{cluster_tools_pod} -- crictl inspecti #{repo_digest}", namespace: TESTSUITE_NAMESPACE)
          begin
            parsed_json = JSON.parse(cricti[:output])
            acc << parsed_json["status"]["id"].as_s
          rescue
            Log.error { "cricti not valid json: #{cricti[:output]}" }
            acc
          end
        end
        Log.info { "id_sha256_list: #{id_sha256_list}" }

        # Fetch image id sha256sums available for all upstream node-exporter releases
        resp = Halite.get("https://registry.hub.docker.com/v2/repositories/bitnami/metrics-server/tags?page=1")
        metrics_server_releases = resp.body
        tag_list = named_sha_list(metrics_server_releases)
        Log.info { "tag_list: #{tag_list}" }
        if ENV["DOCKERHUB_USERNAME"]? && ENV["DOCKERHUB_PASSWORD"]?
            target_ns_repo = "bitnami/metrics-server"
          params = "service=registry.docker.io&scope=repository:#{target_ns_repo}:pull"

          # token is available at the url below
          # curl --user "#{ENV["DOCKERHUB_USERNAME"]}:#{ENV["DOCKERHUB_PASSWORD"]}" "https://auth.docker.io/token?#{params}"
          resp = Halite.basic_auth(user: ENV["DOCKERHUB_USERNAME"], pass: ENV["DOCKERHUB_PASSWORD"]).
            get("https://auth.docker.io/token?#{params}")
          token = resp.body
          if token =~ /incorrect username/
            Log.error { "error: #{token}" }
          end
          parsed_token = JSON.parse(token)
          release_id_list = tag_list.reduce([] of Hash(String, String)) do |acc, tag|
            Log.debug { "tag: #{tag}" }
            tag = tag["name"]

            # image_id is available at the url below
            #
            # curl -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
            #      -H "Authorization:Bearer #{parsed_token["token"].as_s}" \
            #      "https://registry-1.docker.io/v2/#{target_ns_repo}/manifests/#{tag}"
            #
            resp = Halite.auth("Bearer #{parsed_token["token"].as_s}").
              get("https://registry-1.docker.io/v2/#{target_ns_repo}/manifests/#{tag}", 
                  headers: {Accept: "application/vnd.docker.distribution.manifest.v2+json"})
            image_id = resp.body
            parsed_image = JSON.parse(image_id)

            Log.debug { "parsed_image config digest #{parsed_image["config"]["digest"]}" }
            if parsed_image["config"]["digest"]?
                acc << {"name" => tag, "digest"=> parsed_image["config"]["digest"].as_s}
            else
              acc
            end
          end
        else
          puts "DOCKERHUB_USERNAME & DOCKERHUB_PASSWORD Must be set."
          exit 1
        end
        Log.info { "Release id sha256sum list: #{release_id_list}" }

        found = false
        release_name = ""
        release_id_list.each do |x|
          if id_sha256_list.find{|i| i.includes?(x["digest"])}
            found = true
            release_name = x["name"]
          end
        end
        if found
          emoji_metrics_server="📶☠️"
          upsert_passed_task("metrics_server","✔️  PASSED: Your platform is using the #{release_name} release for the metrics server #{emoji_metrics_server}")
        else
          emoji_metrics_server="📶☠️"
          upsert_failed_task("metrics_server", "✖️  FAILED: Your platform does not have the metrics server installed #{emoji_metrics_server}")
        end
      end
    end
  end



def named_sha_list(resp_json)
  Log.debug { "sha_list resp_json: #{resp_json}" }
  parsed_json = JSON.parse(resp_json)
  Log.debug { "sha list parsed json: #{parsed_json}" }
  #if tags then this is a quay repository, otherwise assume docker hub repository
  if parsed_json["tags"]?
    parsed_json["tags"].not_nil!.as_a.reduce([] of Hash(String, String)) do |acc, i|
      acc << {"name" => i["name"].not_nil!.as_s, "manifest_digest" => i["manifest_digest"].not_nil!.as_s}
    end
  else
    parsed_json["results"].not_nil!.as_a.reduce([] of Hash(String, String)) do |acc, i|
      # always use amd64
      amd64image = i["images"].as_a.find{|x| x["architecture"].as_s == "amd64"}
      Log.debug { "amd64image: #{amd64image}" }
      if amd64image && amd64image["digest"]?
        acc << {"name" => i["name"].not_nil!.as_s, "manifest_digest" => amd64image["digest"].not_nil!.as_s}
      else
        Log.error { "amd64 image not found in #{i["images"]}" }
        acc
      end
    end
  end
end
