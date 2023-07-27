require "log"
require "kubectl_client"
require "helm"
require "file_utils"
require "../src/tasks/utils/utils.cr"

module Operator
  module OLM
    def self.install_dir
      "#{tools_path}/olm"
    end

    def self.tmp_dir
      "#{FileUtils.pwd}/tmp"
    end

    def self.install
      # Install OLM
      FileUtils.mkdir_p(self.tmp_dir)
      if Dir.exists?("#{self.install_dir}/olm/.git")
        Log.info { "OLM already installed. Skipping git clone for OLM." }
      else
        GitClient.clone("https://github.com/operator-framework/operator-lifecycle-manager.git #{self.install_dir}")
        `cd #{install_dir} && git fetch -a && git checkout tags/v0.22.0 && cd -`
      end

      begin
        Helm.install("operator --set olm.image.ref=quay.io/operator-framework/olm:v0.22.0 --set catalog.image.ref=quay.io/operator-framework/olm:v0.22.0 --set package.image.ref=quay.io/operator-framework/olm:v0.22.0 #{install_dir}/deploy/chart/")
      rescue e : Helm::CannotReuseReleaseNameError
        Log.info { "operator-lifecycle-manager already installed" }
      end
    end

    def self.cleanup
      pods = [] of Hash(String, String)

      ["catalog-operator","olm-operator", "packageserver"].each do |operator_deployment|
        deployment = KubectlClient::Get.deployment(operator_deployment, "operator-lifecycle-manager")

        Log.info { "Checking operator-lifecycle-manager deployment #{operator_deployment} for pods, json: #{deployment}" }

        unless deployment.as_h.empty?
          pods += KubectlClient::Get.pods_by_resource(deployment, "operator-lifecycle-manager")
        end
      end
      
      Helm.uninstall("operator")
      # TODO: get the correct operator version from whatever file or api so we can delete it properly
      # will require updating KubectlClient::Get to support custom resources
      KubectlClient::Delete.command("csv prometheusoperator.0.47.0")

      pods.map do |pod|
        pod_name = pod.dig("metadata", "name")
        pod_namespace = pod.dig("metadata", "namespace")
        Log.info { "Wait for Uninstall on Pod Name: #{pod_name}, Namespace: #{pod_namespace}" }
        KubectlClient::Get.resource_wait_for_uninstall("Pod", "#{pod_name}", 180, "operator-lifecycle-manager")
      end

      self.clear_namespaces(["operators", "operator-lifecycle-manager", "simple-privileged-operator"])
    end

    def self.clear_namespaces(namespaces)
      namespaces.each do |namespace|
        namespace_file_name = "#{self.tmp_dir}/#{namespace}-namespace-k8s-api-output.json"
        Log.info { "namespace_file : #{namespace_file_name}" }

        second_count = 0
        wait_count = 15
        delete = false

        until delete || second_count > wait_count.to_i
          Log.info { "kubectl get namespace #{namespace} -o json > #{namespace_file_name}" }
          File.write(namespace_file_name, "#{KubectlClient::Get.namespaces(namespace).to_json}")

          json = File.open(namespace_file_name) do |file|
            JSON.parse(file)
          end

          json.as_h.delete("spec")

          Log.info { "#{json.to_json}" }

          File.write(namespace_file_name, "#{json.to_json}")
          Log.info { "Uninstall Namespace Finalizer #{namespace_file_name}" }
          
          result = KubectlClient::Replace.command("--raw \"/api/v1/namespace/#{namespace}/finalize\" -f #{namespace_file_name}")
          if result[:status].success? || result[:error].includes?("NotFound")
            delete = true
          end

          if second_count == wait_count.to_i
            Log.error { "Failed to remove finalizer delete #{namespace} namespace please remove manually" }
          end

          second_count += 1
          sleep 3
        end

        File.delete(namespace_file_name)
      end
    end

    def cleanup_olm
    end

    def self.get_all_subscription_names(resources)
      subscription_names = resources.map do |resource|
        kind = resource.dig("kind").as_s
        if kind && kind.downcase == "subscription"
          {"name" => resource.dig("metadata", "name"), "namespace" => resource.dig("metadata", "namespace")}
        end
      end.compact
    end

    def self.get_all_csv_names_from_subscription_names(subscription_names)
      # TODO Warn if csv is not found for a subscription.
      csv_names = subscription_names.map do |subscription|
        second_count = 0
        wait_count = 120
        csv_created = nil
        resource_created = false

        KubectlClient::Get.wait_for_resource_key_value("sub", "#{subscription["name"]}", {"status", "installedCSV"}, namespace: subscription["namespace"].as_s)

        installed_csv = KubectlClient::Get.resource("sub", "#{subscription["name"]}", "#{subscription["namespace"]}")
        if installed_csv.dig?("status", "installedCSV")
          {"name" => installed_csv.dig("status", "installedCSV"), "namespace" => installed_csv.dig("metadata", "namespace")}
        end
      end.compact
    end

    def self.get_all_csv_names(resources)
      self.get_all_csv_names_from_subscription_names(self.get_all_subscription_names(resources))
    end

    def self.get_all_csv_wait_for_resource_statuses_from_csv_names(csv_names)
      csv_with_wait_for_resource_status = csv_names.map do |csv|
        if KubectlClient::Get.wait_for_resource_key_value("csv", "#{csv["name"]}", {"status", "reason"}, namespace: csv["namespace"].as_s, value: "InstallSucceeded") && KubectlClient::Get.wait_for_resource_key_value("csv", "#{csv["name"]}", {"status", "phase"}, namespace: csv["namespace"].as_s, value: "Succeeded")
          csv["wait_for_resource_status"] = JSON::Any.new("success")
        else
          csv["wait_for_resource_status"] = JSON::Any.new("failure")
        end
        csv
      end
    end

    def self.get_all_successfully_installed_csvs(resources)
      self.get_all_csv_wait_for_resource_statuses_from_csv_names(self.get_all_csv_names(resources)).select do |csv|
        csv["wait_for_resource_status"] == "success"
      end
    end

    def self.get_all_pods_from_installed_csv(csv)
      csv_resource = KubectlClient::Get.resource("csv", "#{csv["name"]}", "#{csv["namespace"]}")

      deployments = csv_resource.dig("install", "deployments")

      deployment_names = deployments.as_a.map do |deployment|
        deployment.dig("name")
      end

      pods = deployment_names.map do |deployment_name|
        KubectlClient::Get.resource("pod", "--selector=name=#{deployment_name}", "#{csv["namespace"]}")
      end.flatten
    end
  end
end
