require "kubectl_client"

module Operator
  module OLM
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
