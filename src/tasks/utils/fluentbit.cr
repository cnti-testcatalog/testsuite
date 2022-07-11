module FluentBit
  def self.install
    #todo use embedded file to install fluentd values over fluent helm
    #chart
    Log.info {"Installing FluentBit daemonset "}
    File.write("fluentbit-config.yml", FLUENTBIT_VALUES)
    Helm.helm_repo_add("fluent", "https://fluent.github.io/helm-charts")

    # Install fluent-bit in the cnf-testsuite namespace
    begin
      Helm.install("--values ./fluentbit-config.yml -n #{TESTSUITE_NAMESPACE} fluent-bit fluent/fluent-bit")
      KubectlClient::Get.resource_wait_for_install("Daemonset", "fluent-bit", namespace: TESTSUITE_NAMESPACE)
    rescue Helm::CannotReuseReleaseNameError
      Log.info { "Falco already installed" }
    end
  end

  def self.uninstall
    Log.for("verbose").info { "uninstall_fluentbit" }
    Helm.delete("fluent-bit -n #{TESTSUITE_NAMESPACE}")
  end

  def self.match()
    ClusterTools.local_match_by_image_name("fluent/fluent-bit")
  end
# todo check if td agent (log forwarder) exists
# todo check if td agent (log aggregrator) exists
  # todo pick a popular fluentd service discovery method and check its
  # configuration files to see if they are configured
  #
  #
  # todo check if fluentd installed (if not, skip)
  def self.installed?
    KubectlClient::Get.resource_wait_for_install("Daemonset", "fluent-bit", namespace: TESTSUITE_NAMESPACE)
  end

  # todo check fluentd log to see if container of application is being
  # tailed
  def self.app_tailed?(pod_name, match=nil)
    Log.info { "app_tailed_by_fluentbit pod_name: #{pod_name} match: #{match}"}
    match = match() unless match
    Log.info { "app_tailed_by_fluentbit match: #{match}"}
    found = false
    fluentbit_pods = KubectlClient::Get.pods_by_digest(match[:digest])
    fluentbit_pods.each do |fluentbit_pod|
      pod_name = fluentbit_pod.dig("metadata","name").as_s
      logs = KubectlClient.logs(pod_name, namespace: TESTSUITE_NAMESPACE)
      Log.debug { "fluentbit logs: #{logs}"}
      found = logs[:output].to_s.includes?(pod_name)
    end
    Log.info { "fluentbit found match: #{found}"}
    found
  end
end
