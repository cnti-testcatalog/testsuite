# coding: utf-8
require "sam"
require "colorize"
require "../utils/utils.cr"

namespace "platform" do
  desc "The CNF conformance suite checks to see if the Platform has Observability support."
  task "observability", ["kube_state_metrics", "node_exporter"] do |t, args|
    VERBOSE_LOGGING.info "resilience" if check_verbose(args)
    VERBOSE_LOGGING.debug "resilience args.raw: #{args.raw}" if check_verbose(args)
    VERBOSE_LOGGING.debug "resilience args.named: #{args.named}" if check_verbose(args)
    stdout_score("platform:resilience")
  end

  desc "Does the Platform have Kube State Metrics installed"
  task "kube_state_metrics" do |_, args|
    unless check_poc(args)
      LOGGING.info "skipping kube_state_metrics: not in poc mode"
      puts "Skipped".colorize(:yellow)
      next
    end
    LOGGING.info "Running POC: kube_state_metrics"
    task_response = task_runner(args) do |args|
      current_dir = FileUtils.pwd 
      # helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"

      # state_metric_releases = `curl -L -s https://quay.io/api/v1/repository/coreos/kube-state-metrics/tag/?limit=100 | jq '.[] | .[] | .name + " " + .manifest_digest'`

      state_metric_releases = `curl -L -s https://quay.io/api/v1/repository/coreos/kube-state-metrics/tag/?limit=100`
      # Get the sha hash for the kube-state-metrics container
      sha_list = named_sha_list(state_metric_releases)
      LOGGING.debug "sha_list: #{sha_list}"

      # TODO find hash for image
      imageids = KubectlClient::Get.all_container_image_ids
      LOGGING.debug "imageids: #{imageids}"
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
        upsert_failed_task("kube_state_metrics", "✖️  FAILURE: Your platform does not have kube state metrics installed #{emoji_kube_state_metrics}")
      end
    end
  end

  desc "Does the Platform have a Node Exporter installed"
  task "node_exporter" do |_, args|
    unless check_poc(args)
      LOGGING.info "skipping node_exporter: not in poc mode"
      puts "Skipped".colorize(:yellow)
      next
    end
    LOGGING.info "Running POC: node_exporter"
    task_response = task_runner(args) do |args|
      current_dir = FileUtils.pwd 

      # Get the sha hash for the kube-state-metrics container
      node_exporter = `curl -L -s 'https://registry.hub.docker.com/v2/repositories/prom/node-exporter/tags?page_size=1024'`
      sha_list = named_sha_list(node_exporter)
      LOGGING.info "sha_list: #{sha_list}"

      imageids = KubectlClient::Get.all_container_image_ids
      LOGGING.info "imageids: #{imageids}"
      found = false
      release_name = ""
      sha_list.each do |x|
        if imageids.find{|i| i.includes?(x["manifest_digest"])}
          found = true
          release_name = x["name"]
        end
      end
      if found
        emoji_node_exporter="📶☠️"
        upsert_passed_task("node_exporter","✔️  PASSED: Your platform is using the #{release_name} release for the node exporter #{emoji_node_exporter}")
      else
        emoji_node_exporter="📶☠️"
        upsert_failed_task("node_exporter", "✖️  FAILURE: Your platform does not have the node exporter installed #{emoji_node_exporter}")
      end
    end
  end
end

def named_sha_list(resp_json)
  LOGGING.debug "sha_list resp_json: #{resp_json}"
  parsed_json = JSON.parse(resp_json)
  LOGGING.debug "sha list parsed json: #{parsed_json}"
  #TODO if tags then this is a quay repository, otherwise assume docker hub repository
  if parsed_json["tags"]?
    parsed_json["tags"].not_nil!.as_a.reduce([] of Hash(String, String)) do |acc, i|
      acc << {"name" => i["name"].not_nil!.as_s, "manifest_digest" => i["manifest_digest"].not_nil!.as_s}
    end
  else
    parsed_json["results"].not_nil!.as_a.reduce([] of Hash(String, String)) do |acc, i|
      #TODO always use amd64
      amd64image = i["images"].as_a.find{|x| x["architecture"].as_s == "amd64"}
      LOGGING.debug "amd64image: #{amd64image}"
      if amd64image && amd64image["digest"]?
        acc << {"name" => i["name"].not_nil!.as_s, "manifest_digest" => amd64image["digest"].not_nil!.as_s}
      else
        LOGGING.error "amd64 image not found in #{i["images"]}"
        acc
      end
    end
  end
end
