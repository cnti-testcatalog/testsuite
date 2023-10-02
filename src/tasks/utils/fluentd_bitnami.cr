module FluentDBitnami
  def self.install
    #todo use embedded file to install fluentd values over fluent helm
    #chart
    Log.info {"Installing FluentD Bitnami daemonset "}
    # File.write("fluentd-values.yml", FLUENTD_VALUES)
    # Helm.helm_repo_add("fluent","https://fluent.github.io/helm-charts")
    Helm.helm_repo_add("bitnami","oci://registry-1.docker.io/bitnamicharts")
    #
    # # Install fluentd in the cnf-testsuite namespace
    # Helm.install("--values ./fluentd-values.yml -n #{TESTSUITE_NAMESPACE} fluentd fluent/fluentd")
    # Helm.helm_repo_add("fluent", "https://fluent.github.io/helm-charts")
    Helm.install("--set aggregator.enabled=false -n #{TESTSUITE_NAMESPACE} fluentd bitnami/fluentd")
    KubectlClient::Get.resource_wait_for_install("Daemonset", "fluentd", namespace: TESTSUITE_NAMESPACE)
  end

  def self.uninstall
    Log.for("verbose").info { "uninstall_fluentd" }
    Helm.delete("fluentd -n #{TESTSUITE_NAMESPACE}")
  end

  def self.match()
    ClusterTools.local_match_by_image_name("bitnami/fluentd")
  end
# todo check if td agent (log forwarder) exists
# todo check if td agent (log aggregrator) exists
  # todo pick a popular fluentd service discovery method and check its
  # configuration files to see if they are configured
  #
  #
  # todo check if fluentd installed (if not, skip)
  def self.installed?
    KubectlClient::Get.resource_wait_for_install("Daemonset", "fluentd", namespace: TESTSUITE_NAMESPACE)
  end

  # todo check fluentd log to see if container of application is being
  # tailed
  def self.app_tailed_by_fluentd?(pod_name, match=nil)
    Log.info { "bitnami app_tailed_by_fluentd pod_name: #{pod_name} match: #{match}"}
    match = match() unless match
    Log.info { "app_tailed_by_fluentd match: #{match}"}
    found = false
    fluentd_pods = KubectlClient::Get.pods_by_digest(match[:digest])
    Log.info { "fluentd_pods match: #{fluentd_pods}"}
    fluentd_pods.each do |fluentd|
      pod_name = fluentd.dig("metadata","name").as_s
      logs = KubectlClient.logs(pod_name, namespace: TESTSUITE_NAMESPACE)
      Log.debug { "fluentd logs: #{logs}"}
      found = logs[:output].to_s.includes?(pod_name)
    end
    Log.info { "fluentd found match: #{found}"}
    found
  end
end
