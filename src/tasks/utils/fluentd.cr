module FluentD 
  def self.match()
    ClusterTools.local_match_by_image_name("fluent/fluentd-kubernetes-daemonset")
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
      pod_name = fluentd.dig("metadata","name").as_s
      logs = KubectlClient.logs(pod_name)
      Log.debug { "fluentd logs: #{logs}"}
      found = logs[:output].to_s.includes?(pod_name)
    end
    Log.info { "fluentd found match: #{found}"}
    found
  end
end
