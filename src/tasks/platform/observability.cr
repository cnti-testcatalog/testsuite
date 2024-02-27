# coding: utf-8
require "sam"
require "colorize"
require "../utils/utils.cr"
require "retriable"
require "k8s_kernel_introspection"

namespace "platform" do
  desc "The CNF test suite checks to see if the Platform has Observability support."
  task "observability", ["kube_state_metrics", "node_exporter", "prometheus_adapter", "metrics_server"] do |t, args|
    Log.for("verbose").info { "observability" } if check_verbose(args)
    Log.for("verbose").debug { "observability args.raw: #{args.raw}" } if check_verbose(args)
    Log.for("verbose").debug { "observability args.named: #{args.named}" } if check_verbose(args)
    stdout_score("platform:observability")
  end

  desc "Does the Platform have Kube State Metrics installed"
  task "kube_state_metrics", ["install_cluster_tools"] do |_, args|
    task_start_time = Time.utc
    testsuite_task = "kube_state_metrics"
    emoji_kube_state_metrics="📶☠️"
    Log.for(testsuite_task).info { "Starting test" }

    unless check_poc(args)
      upsert_skipped_task(testsuite_task, "⏭️  SKIPPED: Kube State Metrics not in poc mode #{emoji_kube_state_metrics}", task_start_time)
      next
    end
    if args.named["offline"]?
      upsert_skipped_task(testsuite_task, "⏭️  SKIPPED: Kube State Metrics in offline mode #{emoji_kube_state_metrics}", task_start_time)
      next
    end
    Log.info { "Running POC: kube_state_metrics" }
    found = KernelIntrospection::K8s.find_first_process(CloudNativeIntrospection::STATE_METRICS_PROCESS)
    Log.info { "Found Pod: #{found}" }

    if found
      upsert_passed_task(testsuite_task,"✔️  PASSED: Your platform is using the release for kube state metrics #{emoji_kube_state_metrics}", task_start_time)
    else
      upsert_failed_task(testsuite_task, "✖️  FAILED: Your platform does not have kube state metrics installed #{emoji_kube_state_metrics}", task_start_time)
    end
  end

  desc "Does the Platform have a Node Exporter installed"
  task "node_exporter", ["install_cluster_tools"] do |_, args|
    task_start_time = Time.utc
    testsuite_task = "node_exporter"
    emoji_node_exporter="📶☠️"
    Log.for(testsuite_task).info { "Starting test" }

    unless check_poc(args)
      upsert_skipped_task(testsuite_task, "⏭️  SKIPPED: node exporter not in poc mode #{emoji_node_exporter}", task_start_time)
      next
    end

    if args.named["offline"]?
      upsert_skipped_task(testsuite_task, "⏭️  SKIPPED: node exporter in offline mode #{emoji_node_exporter}", task_start_time)
      next
    end
    Log.info { "Running POC: node_exporter" }
    found = KernelIntrospection::K8s.find_first_process(CloudNativeIntrospection::NODE_EXPORTER)
    Log.info { "Found Process: #{found}" }
    if found
      upsert_passed_task(testsuite_task,"✔️  PASSED: Your platform is using the node exporter #{emoji_node_exporter}", task_start_time)
    else
      upsert_failed_task(testsuite_task, "✖️  FAILED: Your platform does not have the node exporter installed #{emoji_node_exporter}", task_start_time)
    end
  end


  desc "Does the Platform have the prometheus adapter installed"
  task "prometheus_adapter", ["install_cluster_tools"] do |_, args|
    task_start_time = Time.utc
    testsuite_task = "prometheus_adapter"
    emoji_prometheus_adapter="📶☠️"
    Log.for(testsuite_task).info { "Starting test" }

    unless check_poc(args)
      upsert_skipped_task(testsuite_task, "⏭️  SKIPPED: prometheus adapter not in poc mode #{emoji_prometheus_adapter}", task_start_time)
      next
    end
    if args.named["offline"]?
      upsert_skipped_task(testsuite_task, "⏭️  SKIPPED: prometheus adapter in offline mode #{emoji_prometheus_adapter}", task_start_time)
      next
    end
    Log.info { "Running POC: prometheus_adapter" }
    found = KernelIntrospection::K8s.find_first_process(CloudNativeIntrospection::PROMETHEUS_ADAPTER)
    Log.info { "Found Process: #{found}" }

    if found
      upsert_passed_task(testsuite_task,"✔️  PASSED: Your platform is using the prometheus adapter #{emoji_prometheus_adapter}", task_start_time)
    else
      upsert_failed_task(testsuite_task, "✖️  FAILED: Your platform does not have the prometheus adapter installed #{emoji_prometheus_adapter}", task_start_time)
    end
  end

  desc "Does the Platform have the K8s Metrics Server installed"
  task "metrics_server", ["install_cluster_tools"] do |_, args|
    task_start_time = Time.utc
    testsuite_task = "metrics_server"
    emoji_metrics_server="📶☠️"
    Log.for(testsuite_task).info { "Starting test" }

    unless check_poc(args)
      upsert_skipped_task(testsuite_task, "⏭️  SKIPPED: Metrics server not in poc mode #{emoji_metrics_server}", task_start_time)
      next
    end
    if args.named["offline"]?
      upsert_skipped_task(testsuite_task, "⏭️  SKIPPED: Metrics server in offline mode #{emoji_metrics_server}", task_start_time)
      next
    end
    Log.info { "Running POC: metrics_server" }
    task_response = CNFManager::Task.task_runner(args, check_cnf_installed: false) do |args|

      found = KernelIntrospection::K8s.find_first_process(CloudNativeIntrospection::METRICS_SERVER)
      if found
        upsert_passed_task(testsuite_task, "✔️  PASSED: Your platform is using the metrics server #{emoji_metrics_server}", task_start_time)
      else
        upsert_failed_task(testsuite_task, "✖️  FAILED: Your platform does not have the metrics server installed #{emoji_metrics_server}", task_start_time)
      end
    end
  end
end

def skopeo_sha_list(repo)
  tags = skopeo_tags(repo)
  Log.info { "sha_list tags: #{tags}" }

  if tags
    tags.as_a.reduce([] of Hash(String, String)) do |acc, i|
      acc << {"name" => i.not_nil!.as_s, "manifest_digest" => skopeo_digest("#{repo}:#{i}").as_s}
    end
  end
end

def skopeo_digest(image)
  ClusterTools.install
  resp = ClusterTools.exec("skopeo inspect docker://#{image}")
  Log.info { resp[:output] }
  parsed_json = JSON.parse(resp[:output])
  parsed_json["Digest"]
end

def skopeo_tags(repo)
  ClusterTools.install
  resp = ClusterTools.exec("skopeo list-tags docker://#{repo}")
  Log.info { resp[:output] }
  parsed_json = JSON.parse(resp[:output])
  parsed_json["Tags"]
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
