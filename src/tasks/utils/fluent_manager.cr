module FluentManager
  abstract class FluentBase
    getter flavor_name : String
    getter repo_url : String
    getter values_file : String
    getter values_macro : String
    getter image_name : String
    getter chart : String

    def initialize(flavor_name : String, repo_url : String, values_file : String, values_macro : String, image_name : String, chart : String)
      @flavor_name = flavor_name
      @repo_url = repo_url
      @values_file = values_file
      @values_macro = values_macro
      @image_name = image_name
      @chart = chart
    end

    def install
      Log.info { "Installing #{flavor_name} daemonset using #{values_file}" }
      Helm.helm_repo_add(flavor_name, repo_url)
      File.write(values_file, values_macro)
      begin
        Helm.install("--values #{values_file} -n #{TESTSUITE_NAMESPACE} #{flavor_name} #{chart}")
        KubectlClient::Get.resource_wait_for_install("Daemonset", flavor_name, namespace: TESTSUITE_NAMESPACE)
      rescue Helm::CannotReuseReleaseNameError
        Log.info { "Release #{flavor_name} already installed" }
      end
    end

    def uninstall
      Log.info { "Uninstalling #{flavor_name} in #{TESTSUITE_NAMESPACE}" }
      Helm.delete("#{flavor_name} -n #{TESTSUITE_NAMESPACE}")
    end

    def installed?
      KubectlClient::Get.resource_wait_for_install("Daemonset", flavor_name, namespace: TESTSUITE_NAMESPACE)
    end
  end

  class FluentD < FluentBase
    def initialize
      super("fluentd", 
            "https://fluent.github.io/helm-charts", 
            "fluentd-values.yml",
            FLUENTD_VALUES,
            "fluent/fluentd-kubernetes-daemonset",
            "fluent/fluentd")
    end
  end

  class FluentDBitnami < FluentBase
    def initialize
      super("fluentdbitnami",
            "https://charts.bitnami.com/bitnami",
            "fluentd-bitnami-values.yml",
            FLUENTD_BITNAMI_VALUES,
            "bitnami/fluentd",
            "bitnami/fluentd")
    end
  end

  class FluentBit < FluentBase
    def initialize
      super("fluent-bit", 
            "https://fluent.github.io/helm-charts",
            "fluentbit-values.yml",
            FLUENTBIT_VALUES,
            "fluent/fluent-bit",
            "fluent/fluent-bit")
    end
  end

  def self.find_active_match
    all_flavors.each do |flavor|
      match = ClusterTools.local_match_by_image_name(flavor.image_name)
      return match if match[:found]
    end
    nil
  end

  def self.pod_tailed?(pod_name, match)
    return false unless match

    fluent_pods = KubectlClient::Get.pods_by_digest(match[:digest])
    fluent_pods.each do |fluent_pod|
      fluent_pod_name = fluent_pod.dig("metadata", "name").as_s
      logs = KubectlClient.logs(fluent_pod_name, namespace: TESTSUITE_NAMESPACE)
      Log.info { "Searching logs of #{fluent_pod_name} for string #{pod_name}" }
      Log.debug { "Fluent logs: #{logs}" }
      return true if logs[:output].to_s.includes?(pod_name)
    end

    false
  end

  def self.all_flavors : Array(FluentBase)
    [FluentD.new, FluentDBitnami.new, FluentBit.new]
  end
end
