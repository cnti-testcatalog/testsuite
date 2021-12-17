module FluentD 
  def self.match()
    match = ClusterTools.local_match_by_image_name("fluent/fluentd-kubernetes-daemonset")
    # do_this_on_each_retry = ->(ex : Exception, attempt : Int32, elapsed_time : Time::Span, next_interval : Time::Span) do
    #   Log.info { "#{ex.class}: '#{ex.message}' - #{attempt} attempt in #{elapsed_time} seconds and #{next_interval} seconds until the next try."}
    # end
    #
    # # Retriable.retry(on_retry: do_this_on_each_retry, times: 3, base_interval: 1.second) do
    #   # resp = Halite.get("https://quay.io/api/v1/repository/prometheus/prometheus/tag/?onlyActiveTags=true&limit=100")
    # if pagination
    #   page = 1
    #   resp =
    #     #todo change to look up local tag based on image name, then look up the image/tag on docker hub.  this will reduce docker hub calls
    #     Halite.get("https://hub.docker.com/v2/repositories/fluent/fluentd-kubernetes-daemonset/tags?page=1&page_size=100", headers: {"Authorization" => "JWT"})
    #   docker_resp = resp.body
    #   sha_list = named_sha_list(docker_resp)
    #   imageids = KubectlClient::Get.all_container_repo_digests
    #   match = DockerClient::K8s.local_digest_match(sha_list, imageids)
    #   while match[:found]==false && page < 100
    #     Log.info { "page: #{page}".colorize(:yellow)}
    #
    #     resp =
    #       Halite.get("https://hub.docker.com/v2/repositories/fluent/fluentd-kubernetes-daemonset/tags?page=#{page}&page_size=100", headers: {"Authorization" => "JWT"})
    #     docker_resp = resp.body
    #     sha_list = named_sha_list(docker_resp)
    #     imageids = KubectlClient::Get.all_container_repo_digests
    #     match = DockerClient::K8s.local_digest_match(sha_list, imageids)
    #     page = page + 1
    #   end
    # else
    #   resp =
    #     Halite.get("https://hub.docker.com/v2/repositories/fluent/fluentd-kubernetes-daemonset/tags?page=1&page_size=100", headers: {"Authorization" => "JWT"})
    #   docker_resp = resp.body
    #   sha_list = named_sha_list(docker_resp)
    #   imageids = KubectlClient::Get.all_container_repo_digests
    #   match = DockerClient::K8s.local_digest_match(sha_list, imageids)
    # end
    # # end
    match
  end
# todo check if td agent (log forwarder) exists
# todo check if td agent (log aggregrator) exists
  # todo pick a popular fluentd service discovery method and check its
  # configuration files to see if they are configured
  #
  #
  # todo check if fluentd installed (if not, skip)
  def self.installed?
    KubectlClient::Get.resource_wait_for_install("Daemonset", "fluentd")
  end
  # todo check fluentd log to see if container of application is being
  # tailed
  def self.app_tailed_by_fluentd?(pod_name, match=nil)
    Log.info { "app_tailed_by_fluentd pod_name: #{pod_name} match: #{match}"}
    match = match() unless match
    Log.info { "app_tailed_by_fluentd match: #{match}"}
    found = false
    fluentd_pods = KubectlClient::Get.pods_by_digest(match[:digest])
    fluentd_pods.each do |fluentd|
      logs = KubectlClient.logs(fluentd.dig?("metadata","name"))
      Log.debug { "fluentd logs: #{logs}"}
      found = logs[:output].to_s.includes?(pod_name.as_s)
    end
    Log.info { "fluentd found match: #{found}"}
    found
  end
end
