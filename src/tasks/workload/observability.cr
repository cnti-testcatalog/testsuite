require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "In order to maintain, debug, and have insight into a protected environment, its infrastructure elements must have the property of being observable. This means these elements must externalize their internal states in some way that lends itself to metrics, tracing, and logging."
task "observability", ["log_output"] do |_, args|
end

desc "Check if the CNF outputs logs to stdout or stderr"
task "log_output" do |_, args|
  CNFManager::Task.task_runner(args) do |args,config|
    Log.for("verbose").info { "log_output" } if check_verbose(args)

    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = false
      case resource["kind"].as_s.downcase
      when "replicaset", "deployment", "statefulset", "pod", "daemonset"
        result = KubectlClient.logs("#{resource["kind"]}/#{resource["name"]}", "--all-containers --tail=5 --prefix=true")
        Log.for("Log lines").info { result[:output] }
        if result[:output].size > 0
          test_passed = true
        end
      end
      test_passed
    end

    emoji_observability="📶☠️"
    emoji_observability="📶☠️"

    if task_response
      upsert_passed_task("log_output", "✔️  PASSED: Resources output logs to stdout and stderr #{emoji_observability}")
    else
      upsert_failed_task("log_output", "✖️  FAILED: Resources do not output logs to stdout and stderr #{emoji_observability}")
    end
  end
end

desc "Does the CNF emit prometheus traffic"
task "prometheus_traffic" do |_, args|

  # if args.named["offline"]?
  #     Log.info { "skipping prometheus_adapter: in offline mode" }
  #   puts "SKIPPED: Prometheus Adapter".colorize(:yellow)
  #   next
  # end
  Log.info { "Running: prometheus_traffic" }
  task_response = CNFManager::Task.task_runner(args) do |args, config|

    release_name = config.cnf_config[:release_name]

    do_this_on_each_retry = ->(ex : Exception, attempt : Int32, elapsed_time : Time::Span, next_interval : Time::Span) do
      Log.info { "#{ex.class}: '#{ex.message}' - #{attempt} attempt in #{elapsed_time} seconds and #{next_interval} seconds until the next try."}
    end

    emoji_observability="📶☠️"

    Retriable.retry(on_retry: do_this_on_each_retry, times: 3, base_interval: 1.second) do
      # todo local_image_digest_by_remote_url
      resp = Halite.get("https://quay.io/api/v1/repository/prometheus/prometheus/tag/?onlyActiveTags=true&limit=100")
      prometheus_server_releases = resp.body
      sha_list = named_sha_list(prometheus_server_releases)
      imageids = KubectlClient::Get.all_container_repo_digests
      match = DockerClient::K8s.local_digest_match(sha_list, imageids)
      if match[:found]
        # matched_service = KubectlClient::Get.service_by_digest(match[:digest])
        service = KubectlClient::Get.service_by_digest(match[:digest])
        service_url = service.dig("metadata", "name") 

        Log.info { "service_url: #{service_url}"}
        ClusterTools.install
        # todo call from install cni container
        # todo make a prerequisite for cluster_tools
        # todo cluster_tools_exec command
        # pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
        # pods = KubectlClient::Get.pods_by_label(pods, "name", "cluster-tools")
        #
        # File.write("cluster_tools.yml", CLUSTER_TOOLS)
        # KubectlClient::Apply.file("cluster_tools.yml")
        #
        # KubectlClient::Get.wait_for_cluster_tools
        # cluster_tools_pod_name = pods[0].dig?("metadata", "name") if pods[0]?
        # Log.info { "cluster_tools_pod_name: #{cluster_tools_pod_name}"}
        # prom_api_resp  = KubectlClient.exec("--namespace=default -ti #{cluster_tools_pod_name} -- curl http://#{service_url}/api/v1/targets?state=active")  
        prom_api_resp = ClusterTools.exec("curl http://#{service_url}/api/v1/targets?state=active")

        # prom_api_resp = Halite.get("http://#{service_url}/api/v1/targets?state=active")
        Log.debug { "prom_api_resp: #{prom_api_resp}"}
        #todo prometheus module, promte_target_urls from resp
        prom_json = JSON.parse(prom_api_resp[:output])
        #todo get cnf ip address
        matched_target = false
        active_targets = prom_json.dig("data", "activeTargets")
        Log.debug { "active_targets: #{active_targets}"}
        prom_target_urls = active_targets.as_a.reduce([] of String) do |acc, target|
          acc << target.dig("scrapeUrl").as_s
          acc << target.dig("globalUrl").as_s
        end
        Log.info { "prom_target_urls: #{prom_target_urls}"}
        prom_cnf_match = CNFManager.workload_resource_test(args, config) do |resource_name, container, initialized|
          ip_match = false
          resource = KubectlClient::Get.resource(resource_name[:kind], resource_name[:name])
          pods = KubectlClient::Get.pods_by_resource(resource)
          pods.each do |pod|
            pod_ips = pod.dig("status", "podIPs")
            Log.info { "pod_ips: #{pod_ips}"}
            pod_ips.as_a.each do |ip|
              prom_target_urls.each do |url|
                Log.info { "checking: #{url} against #{ip.dig("ip").as_s}"}
                if url.includes?(ip.dig("ip").as_s)
                  cnf_metrics_resp = ClusterTools.exec("curl #{url}")
                  # todo prometheus module, call/validate_cnf_metric_url
                  # todo config map test for open metrics
                  #todo    query cnf metrics endpoint
                  # e.g cluster tool cli 
                  #todo    validation of metrics response
                  # todo rescue?
                  io = IO::Memory.new
                  io << cnf_metrics_resp[:output]
                  msg = Openmetrics::Metric.from_protobuf(io) # returns a an instance of MyMessage
                                                   # from a valid protobuf encoded message
                  Log.info { "Openmetrics msg: #{msg}"}
                  # Log.info { "save config" }
                  # elapsed_time_template = OpenMetricConfigMapTemplate.new(
                  #   "cnf-testsuite-#{release_name}-startup-information",
                  #   helm_used,
                  #   "#{elapsed_time.seconds}",
                  #   immutable_configmap
                  # ).to_s
                  # #TODO find a way to kubectlapply directly without a map
                  # Log.debug { "elapsed_time_template : #{elapsed_time_template}" }
                  # File.write("#{destination_cnf_dir}/configmap_test.yml", "#{elapsed_time_template}")
                  # # TODO if the config map exists on install, complain, delete then overwrite?
                  # KubectlClient::Delete.file("#{destination_cnf_dir}/configmap_test.yml")
                  # #TODO call kubectl apply on file
                  # KubectlClient::Apply.file("#{destination_cnf_dir}/configmap_test.yml")
                  # # TODO when uninstalling, remove config map
                  # # TODO in specs remove config map when done
                  ip_match = true
                end
              end
            end
          end
         ip_match 
        end

        # todo 1) check if scrape_url is ip address that directly matches cnf
        # todo 2) check if scrape_url is ip address that maps to service
        #  -- get ip address for the service
        #  -- match ip address to cnf ip addresses
        # todo check if scrape_url is not an ip, assume it is a service, then do task (2)
        if prom_cnf_match
          upsert_passed_task("prometheus_traffic","✔️  PASSED: Your cnf is sending prometheus traffic #{emoji_observability}")
        else
          upsert_failed_task("prometheus_traffic", "✖️  FAILED: Your cnf is not sending prometheus traffic #{emoji_observability}")
        end
      else
        upsert_skipped_task("prometheus_traffic", "✖️  SKIPPED: Prometheus server not found #{emoji_observability}")
      end
    end
  end

  desc "Does the CNF emit prometheus open metric compatible traffic"
  task "open_metrics", ["prometheus_traffic"] do |_, args|
    #todo check openmetrics config map for current cnf
    #
    # configmap = KubectlClient::Get.configmap("cnf-testsuite-#{release_name}-startup-information")
    # #TODO check if json is empty
    # startup_time = configmap["data"].as_h["startup_time"].as_s
  end
end
