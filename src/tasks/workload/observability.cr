# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "In order to maintain, debug, and have insight into a protected environment, its infrastructure elements must have the property of being observable. This means these elements must externalize their internal states in some way that lends itself to metrics, tracing, and logging."
task "observability", ["log_output", "prometheus_traffic", "open_metrics", "routed_logs", "tracing"] do |_, args|
  stdout_score("observability")
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
  Log.info { "Running: prometheus_traffic" }
  next if args.named["offline"]?
  task_response = CNFManager::Task.task_runner(args) do |args, config|

    release_name = config.cnf_config[:release_name]
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir] 

    do_this_on_each_retry = ->(ex : Exception, attempt : Int32, elapsed_time : Time::Span, next_interval : Time::Span) do
      Log.info { "#{ex.class}: '#{ex.message}' - #{attempt} attempt in #{elapsed_time} seconds and #{next_interval} seconds until the next try."}
    end

    emoji_observability="📶☠️"

    Retriable.retry(on_retry: do_this_on_each_retry, times: 3, base_interval: 1.second) do
      resp = Halite.get("https://quay.io/api/v1/repository/prometheus/prometheus/tag/?onlyActiveTags=true&limit=100")
      prometheus_server_releases = resp.body
      sha_list = named_sha_list(prometheus_server_releases)
      imageids = KubectlClient::Get.all_container_repo_digests
      match = DockerClient::K8s.local_digest_match(sha_list, imageids)
      if match[:found]
        service = KubectlClient::Get.service_by_digest(match[:digest])
        service_url = service.dig("metadata", "name") 

        Log.info { "service_url: #{service_url}"}
        ClusterTools.install
        prom_api_resp = ClusterTools.exec("curl http://#{service_url}/api/v1/targets?state=active")

        Log.debug { "prom_api_resp: #{prom_api_resp}"}
        prom_json = JSON.parse(prom_api_resp[:output])
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
                  msg = Prometheus.open_metric_validator(url)
                  # Immutable config maps are only supported in Kubernetes 1.19+
                  immutable_configmap = true

                  if version_less_than(KubectlClient.server_version, "1.19.0")
                    immutable_configmap = false
                  end
                  if msg[:status].success?
                    metrics_config_map = Prometheus::OpenMetricConfigMapTemplate.new(
                      "cnf-testsuite-#{release_name}-open-metrics",
                      true,
                      "",
                      immutable_configmap
                    ).to_s
                  else
                    Log.info { "Openmetrics failure reason: #{msg[:output]}"}
                    metrics_config_map = Prometheus::OpenMetricConfigMapTemplate.new(
                      "cnf-testsuite-#{release_name}-open-metrics",
                      false,
                      msg[:output],
                      immutable_configmap
                    ).to_s
                  end

                  Log.debug { "metrics_config_map : #{metrics_config_map}" }
                  configmap_path = "#{destination_cnf_dir}/config_maps/metrics_configmap.yml"
                  File.write(configmap_path, "#{metrics_config_map}")
                  KubectlClient::Delete.file(configmap_path)
                  KubectlClient::Apply.file(configmap_path)
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
        upsert_skipped_task("prometheus_traffic", "⏭️  SKIPPED: Prometheus server not found #{emoji_observability}")
      end
    end
  end
end

desc "Does the CNF emit prometheus open metric compatible traffic"
task "open_metrics", ["prometheus_traffic"] do |_, args|
  Log.info { "Running: open_metrics" }
  next if args.named["offline"]?
  task_response = CNFManager::Task.task_runner(args) do |args, config|
    release_name = config.cnf_config[:release_name]
    configmap = KubectlClient::Get.configmap("cnf-testsuite-#{release_name}-open-metrics")
    emoji_observability="📶☠️"
    if configmap != EMPTY_JSON
      open_metrics_validated = configmap["data"].as_h["open_metrics_validated"].as_s

      if open_metrics_validated == "true"
        upsert_passed_task("open_metrics","✔️  PASSED: Your cnf's metrics traffic is Open Metrics compatible #{emoji_observability}")
      else
        open_metrics_response = configmap["data"].as_h["open_metrics_response"].as_s
        puts "Open Metrics Failed: #{open_metrics_response}".colorize(:red)
        upsert_failed_task("open_metrics", "✖️  FAILED: Your cnf's metrics traffic is not Open Metrics compatible #{emoji_observability}")
      end
    else
      upsert_skipped_task("open_metrics", "⏭️  SKIPPED: Prometheus traffic not configured #{emoji_observability}")
    end
  end
end

desc "Are the CNF's logs captured by a logging system"
task "routed_logs" do |_, args|
  Log.info { "Running: routed_logs" }
  next if args.named["offline"]?
    emoji_observability="📶☠️"
  task_response = CNFManager::Task.task_runner(args) do |args, config|
    match = FluentD.match()
    Log.info { "fluentd match: #{match}" }
    if match[:found]
        all_resourced_logged = CNFManager.workload_resource_test(args, config) do |resource_name, container, initialized|
          resource_logged = true 
          resource = KubectlClient::Get.resource(resource_name[:kind], resource_name[:name])
          pods = KubectlClient::Get.pods_by_resource(resource)
          pods.each do |pod|
            # if any pod/container is not monitored by fluentd, fail
            if resource_logged
              resource_logged = FluentD.app_tailed_by_fluentd?(pod.dig("metadata", "name"), match)
            end
          end
          resource_logged
        end
        Log.info { "all_resourced_logged: #{all_resourced_logged}" }
        if all_resourced_logged 
          upsert_passed_task("routed_logs","✔️  PASSED: Your cnf's logs are being captured #{emoji_observability}")
        else
          upsert_failed_task("routed_logs", "✖️  FAILED: Your cnf's logs are not being captured #{emoji_observability}")
        end
    else
      upsert_skipped_task("routed_logs", "⏭️  SKIPPED: Fluentd not configured #{emoji_observability}")
    end
  end
end

desc "Does the CNF install use tracing?"
task "tracing" do |_, args|
  Log.for("verbose").info { "tracing" } if check_verbose(args)
  Log.info { "tracing args: #{args.inspect}" }
  next if args.named["offline"]?
  match = JaegerManager.match()
  Log.info { "jaeger match: #{match}" }
  emoji_tracing_deploy="⎈🚀"
  if match[:found]
    if check_cnf_config(args) || CNFManager.destination_cnfs_exist?
      CNFManager::Task.task_runner(args) do |args, config|

        helm_chart = config.cnf_config[:helm_chart]
        helm_directory = config.cnf_config[:helm_directory]
        release_name = config.cnf_config[:release_name]
        yml_file_path = config.cnf_config[:yml_file_path]
        configmap = KubectlClient::Get.configmap("cnf-testsuite-#{release_name}-startup-information")
        #TODO check if json is empty
        tracing_used = configmap["data"].as_h["tracing_used"].as_s

        if tracing_used == "true" 
          upsert_passed_task("tracing", "✔️  PASSED: Tracing used #{emoji_tracing_deploy}")
        else
          upsert_failed_task("tracing", "✖️  FAILED: Tracing not used #{emoji_tracing_deploy}")
        end
      end
    else
      upsert_failed_task("tracing", "✖️  FAILED: No cnf_testsuite.yml found! Did you run the setup task?")
    end
  else
    upsert_skipped_task("tracing", "✖️  SKIPPED: Jaeger not configured #{emoji_tracing_deploy}")
  end
end

