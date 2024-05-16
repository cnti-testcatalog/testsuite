module FluentManagement
  CONFIG = {
    "fluentd": {
      repo_url: "https://fluent.github.io/helm-charts",
      values_file: "fluentd-values.yml",
      values_macro: FLUENTD_VALUES,
      image_name: "fluent/fluentd-kubernetes-daemonset",
      chart: "fluent/fluentd"
    },
    "fluentdbitnami": {
      repo_url: "https://charts.bitnami.com/bitnami",
      values_file: "fluentd-bitnami-values.yml",
      values_macro: FLUENTD_BITNAMI_VALUES,
      image_name: "bitnami/fluentd",
      chart: "bitnami/fluentd"
    },
    "fluent-bit": {
      repo_url: "https://fluent.github.io/helm-charts",
      values_file: "fluentbit-values.yml",
      values_macro: FLUENTBIT_VALUES,
      image_name: "fluent/fluent-bit",
      chart: "fluent/fluent-bit"
    }
  }
  
  def self.install(flavor : String)
    config = CONFIG[flavor]

    Log.info { "Installing #{flavor} daemonset using #{config[:values_file]}" }
    Helm.helm_repo_add(flavor, config[:repo_url])
    File.write(config[:values_file], config[:values_macro])
    begin
      Helm.install("--values #{config[:values_file]} -n #{TESTSUITE_NAMESPACE} #{flavor} #{config[:chart]}")
      KubectlClient::Get.resource_wait_for_install("Daemonset", flavor, namespace: TESTSUITE_NAMESPACE)
    rescue Helm::CannotReuseReleaseNameError
      Log.info { "Release #{flavor} already installed" }
    end
  end
  
  def self.uninstall(flavor : String)
    config = CONFIG[flavor]
    Log.info { "Uninstalling #{flavor} in #{TESTSUITE_NAMESPACE}" }
    Helm.delete("#{flavor} -n #{TESTSUITE_NAMESPACE}")
  end

  # TODOs copied from older code, not sure how relevant they still are
  # todo check if td agent (log forwarder) exists
  # todo check if td agent (log aggregrator) exists
  # todo pick a popular fluentd service discovery method and check its
  # configuration files to see if they are configured
  # todo check if fluentd installed (if not, skip)
  def self.installed?(flavor : String)
    config = CONFIG[flavor]
    KubectlClient::Get.resource_wait_for_install("Daemonset", flavor, namespace: TESTSUITE_NAMESPACE)
  end

  def self.find_active_match
    CONFIG.each do |_, settings|
      match = ClusterTools.local_match_by_image_name(settings[:image_name])
      return match if match[:found]
    end

    nil
  end

  def self.pod_tailed?(pod_name, match)
    return false unless match  # Return immediately if match is nil

    fluent_pods = KubectlClient::Get.pods_by_digest(match[:digest])
    fluent_pods.each do |fluent_pod|
      fluent_pod_name = fluent_pod.dig("metadata","name").as_s
      logs = KubectlClient.logs(fluent_pod_name, namespace: TESTSUITE_NAMESPACE)
      Log.info { "Searching logs of #{fluent_pod_name} for string #{pod_name}" }
      Log.debug { "Fluent logs: #{logs}"}
      return true if logs[:output].to_s.includes?(pod_name)
    end

    false
  end
end