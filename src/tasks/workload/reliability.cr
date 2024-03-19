# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "../utils/utils.cr"

desc "The CNF test suite checks to see if the CNFs are resilient to failures."
 task "resilience", [
   "pod_network_latency",
   "pod_network_corruption",
   "disk_fill",
   "pod_delete",
   "pod_memory_hog",
   "pod_io_stress",
   "pod_dns_error",
   "pod_network_duplication",
   "liveness",
   "readiness"
  ] do |t, args|
  Log.for("verbose").info {  "resilience" } if check_verbose(args)
  VERBOSE_LOGGING.debug "resilience args.raw: #{args.raw}" if check_verbose(args)
  VERBOSE_LOGGING.debug "resilience args.named: #{args.named}" if check_verbose(args)
  stdout_score("resilience", "Reliability, Resilience, and Availability")
  case "#{ARGV.join(" ")}" 
  when /reliability/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end

desc "Is there a liveness entry in the helm chart?"
task "liveness" do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    resp = ""
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
      resource_ref = "#{resource[:kind]}/#{resource[:name]}"
      begin
        Log.for(t.name).debug { container.as_h["name"].as_s } if check_verbose(args)
        container.as_h["livenessProbe"].as_h
      rescue ex
        Log.for(t.name).error { ex.message } if check_verbose(args)
        test_passed = false
        stdout_failure("No livenessProbe found for container #{container.as_h["name"].as_s} part of #{resource_ref} in #{resource[:namespace]} namespace")
      end
      Log.for(t.name).info { "Resource #{resource_ref} passed liveness?: #{test_passed}" }
      test_passed
    end
    Log.for(t.name).info { "Workload resource task response: #{task_response}" }
    if task_response
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "Helm liveness probe found")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "No livenessProbe found")
    end
  end
end

desc "Is there a readiness entry in the helm chart?"
task "readiness" do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    resp = ""
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
      resource_ref = "#{resource[:kind]}/#{resource[:name]}"
      begin
        Log.for(t.name).debug { container.as_h["name"].as_s } if check_verbose(args)
        container.as_h["readinessProbe"].as_h
      rescue ex
        Log.for(t.name).error { ex.message } if check_verbose(args)
        test_passed = false
        stdout_failure("No readinessProbe found for container #{container.as_h["name"].as_s} part of #{resource_ref} in #{resource[:namespace]} namespace")
      end
      Log.for(t.name).info { "Resource #{resource_ref} passed liveness?: #{test_passed}" }
      test_passed
    end
    Log.for(t.name).info { "Workload resource task response: #{task_response}" }
    if task_response
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "Helm readiness probe found")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "No readinessProbe found")
    end
  end
end


desc "Does the CNF crash when network latency occurs"
task "pod_network_latency", ["install_litmus"] do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    #todo if args has list of labels to perform test on, go into pod specific mode
    #TODO tests should fail if cnf not installed
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      Log.info { "Current Resource Name: #{resource["name"]} Type: #{resource["kind"]}" }
      app_namespace = resource[:namespace] || config.cnf_config[:helm_install_namespace]

      spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"])
      if spec_labels.as_h? && spec_labels.as_h.size > 0 && resource["kind"] == "Deployment"
        test_passed = true
      else
        stdout_failure("Resource is not a Deployment or no resource label was found for resource: #{resource["name"]}")
        test_passed = false
      end

      current_pod_key = ""
      current_pod_value = ""
      if args.named["pod_labels"]?
          pod_label = args.named["pod_labels"]?
          match_array = pod_label.to_s.split(",")

        test_passed = match_array.any? do |key_value|
          key, value = key_value.split("=")
          if spec_labels.as_h.has_key?(key) && spec_labels[key] == value
            current_pod_key = key
            current_pod_value = value
            Log.info { "Match found for key: #{key} and value: #{value}"}
            true
          else
            Log.info { "Match not found for key: #{key} and value: #{value}"}
            false
          end
        end
      end

      Log.info { "Spec Hash: #{args.named["pod_labels"]?}" }


      if test_passed
        Log.info { "Running for: #{spec_labels}"}
        Log.info { "Spec Hash: #{args.named["pod_labels"]?}" }
        if args.named["offline"]?
            Log.info { "install resilience offline mode" }
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/lat-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/lat-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/lat-rbac.yaml")
        else
          # experiment_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-latency/experiment.yaml"
          experiment_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-network-latency/experiment.yaml"
          # rbac_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-latency/rbac.yaml"
          #           https://raw.githubusercontent.com/litmuschaos/chaos-charts/v2.14.x/charts/generic/pod-network-latency/rbac.yaml 
          rbac_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-network-latency/rbac.yaml"

          experiment_path = LitmusManager.download_template(experiment_url, "#{t.name}_experiment.yaml")
          KubectlClient::Apply.file(experiment_path, namespace: app_namespace)

          rbac_path = LitmusManager.download_template(rbac_url, "#{t.name}_rbac.yaml")
          rbac_yaml = File.read(rbac_path)
          rbac_yaml = rbac_yaml.gsub("namespace: default", "namespace: #{app_namespace}")
          File.write(rbac_path, rbac_yaml)
          KubectlClient::Apply.file(rbac_path)
        end
        #TODO Use Labels to Annotate, not resource["name"]
        KubectlClient::Annotate.run("--overwrite -n #{app_namespace} deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-network-latency"
        total_chaos_duration = "60"
        test_name = "#{resource["name"]}-#{Random::Secure.hex(4)}"
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        #spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"]).as_h
        if args.named["pod_labels"]?
            template = ChaosTemplates::PodNetworkLatency.new(
              test_name,
              "#{chaos_experiment_name}",
              app_namespace,
              "#{current_pod_key}",
              "#{current_pod_value}",
              total_chaos_duration
        ).to_s
        else
          template = ChaosTemplates::PodNetworkLatency.new(
            test_name,
            "#{chaos_experiment_name}",
            app_namespace,
            "#{spec_labels.as_h.first_key}",
            "#{spec_labels.as_h.first_value}",
            total_chaos_duration
          ).to_s
        end

        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args, namespace: app_namespace)
        test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args, namespace: app_namespace)
      end
    end
    unless args.named["pod_labels"]?
        #todo if in pod specific mode, dont do upserts and resp = ""
        if task_response
          CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "pod_network_latency chaos test passed")
        else
          CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "pod_network_latency chaos test failed")
        end
    end

  end
end

desc "Does the CNF crash when network corruption occurs"
task "pod_network_corruption", ["install_litmus"] do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    #TODO tests should fail if cnf not installed
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      Log.info {"Current Resource Name: #{resource["name"]} Type: #{resource["kind"]}"}
      app_namespace = resource[:namespace] || config.cnf_config[:helm_install_namespace]
      spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"])
      if spec_labels.as_h? && spec_labels.as_h.size > 0 && resource["kind"] == "Deployment"
        test_passed = true
      else
        stdout_failure("Resource is not a Deployment or no resource label was found for resource: #{resource["name"]}")
        test_passed = false
      end
      if test_passed
        if args.named["offline"]?
          Log.info {"install resilience offline mode"}
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/corr-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/corr-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/corr-rbac.yaml")
        else
          experiment_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-corruption/experiment.yaml"
          experiment_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-network-corruption/experiment.yaml"
          # rbac_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-corruption/rbac.yaml"
          rbac_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-network-corruption/rbac.yaml"

          experiment_path = LitmusManager.download_template(experiment_url, "#{t.name}_experiment.yaml")
          KubectlClient::Apply.file(experiment_path, namespace: app_namespace)

          rbac_path = LitmusManager.download_template(rbac_url, "#{t.name}_rbac.yaml")
          rbac_yaml = File.read(rbac_path)
          rbac_yaml = rbac_yaml.gsub("namespace: default", "namespace: #{app_namespace}")
          File.write(rbac_path, rbac_yaml)
          KubectlClient::Apply.file(rbac_path)
        end
        KubectlClient::Annotate.run("--overwrite -n #{app_namespace} deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-network-corruption"
        total_chaos_duration = "60"
        test_name = "#{resource["name"]}-#{Random.rand(99)}"
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"]).as_h
        template = ChaosTemplates::PodNetworkCorruption.new(
          test_name,
          "#{chaos_experiment_name}",
          app_namespace,
          "#{spec_labels.first_key}",
          "#{spec_labels.first_value}",
          total_chaos_duration
        ).to_s
        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration, args, namespace: app_namespace)
        test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name, args, namespace: app_namespace)
      end
    end
    if task_response
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "pod_network_corruption chaos test passed")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "pod_network_corruption chaos test failed")
    end
  end
end

desc "Does the CNF crash when network duplication occurs"
task "pod_network_duplication", ["install_litmus"] do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    #TODO tests should fail if cnf not installed
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      app_namespace = resource[:namespace] || config.cnf_config[:helm_install_namespace]
      Log.info{ "Current Resource Name: #{resource["name"]} Type: #{resource["kind"]} Namespace: #{resource["namespace"]}"}
      spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"])
      if spec_labels.as_h? && spec_labels.as_h.size > 0 && resource["kind"] == "Deployment"
        test_passed = true
      else
        stdout_failure("Resource is not a Deployment or no resource label was found for resource: #{resource["kind"]}/#{resource["name"]} in #{resource["namespace"]} namespace")
        test_passed = false
      end
      if test_passed
        if args.named["offline"]?
          Log.info {"install resilience offline mode"}
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/dup-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/dup-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/dup-rbac.yaml")
        else
          # experiment_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-duplication/experiment.yaml"
          experiment_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-network-duplication/experiment.yaml"
          # rbac_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-duplication/rbac.yaml"
          rbac_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-network-duplication/rbac.yaml"

          experiment_path = LitmusManager.download_template(experiment_url, "#{t.name}_experiment.yaml")
          KubectlClient::Apply.file(experiment_path, namespace: app_namespace)

          rbac_path = LitmusManager.download_template(rbac_url, "#{t.name}_rbac.yaml")
          rbac_yaml = File.read(rbac_path)
          rbac_yaml = rbac_yaml.gsub("namespace: default", "namespace: #{app_namespace}")
          File.write(rbac_path, rbac_yaml)
          KubectlClient::Apply.file(rbac_path)
        end
        KubectlClient::Annotate.run("--overwrite -n #{app_namespace} deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-network-duplication"
        total_chaos_duration = "60"
        test_name = "#{resource["name"]}-#{Random.rand(99)}"
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"]).as_h
        template = ChaosTemplates::PodNetworkDuplication.new(
          test_name,
          "#{chaos_experiment_name}",
          app_namespace,
          "#{spec_labels.first_key}",
          "#{spec_labels.first_value}",
          total_chaos_duration
        ).to_s
        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args, namespace: app_namespace)
        test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args, namespace: app_namespace)
      end
    end
    if task_response
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "pod_network_duplication chaos test passed")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "pod_network_duplication chaos test failed")
    end
  end
end

desc "Does the CNF crash when disk fill occurs"
task "disk_fill", ["install_litmus"] do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      app_namespace = resource[:namespace] || config.cnf_config[:helm_install_namespace]
      spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"])
      if spec_labels.as_h? && spec_labels.as_h.size > 0
        test_passed = true
      else
        stdout_failure("No resource label found for #{t.name} test for resource: #{resource["kind"]}/#{resource["name"]} in #{resource["namespace"]} namespace")
        test_passed = false
      end
      if test_passed
        if args.named["offline"]?
          Log.info { "install resilience offline mode" }
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/disk-fill-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/disk-fill-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/disk-fill-rbac.yaml")
        else
          # experiment_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/disk-fill/experiment.yaml"
          experiment_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/disk-fill/experiment.yaml"
          # rbac_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/disk-fill/rbac.yaml"
          rbac_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/disk-fill/rbac.yaml"

          experiment_path = LitmusManager.download_template(experiment_url, "#{t.name}_experiment.yaml")
          KubectlClient::Apply.file(experiment_path, namespace: app_namespace)

          rbac_path = LitmusManager.download_template(rbac_url, "#{t.name}_rbac.yaml")
          rbac_yaml = File.read(rbac_path)
          rbac_yaml = rbac_yaml.gsub("namespace: default", "namespace: #{app_namespace}")
          File.write(rbac_path, rbac_yaml)
          KubectlClient::Apply.file(rbac_path)
        end
        KubectlClient::Annotate.run("--overwrite -n #{app_namespace} deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "disk-fill"
        disk_fill_time = "100"
        test_name = "#{resource["name"]}-#{Random.rand(99)}"
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"]).as_h
        Log.for("#{test_name}:spec_labels").info { "Spec labels for chaos template. Key: #{spec_labels.first_key}; Value: #{spec_labels.first_value}" }
        # todo change to use all labels instead of first label
        template = ChaosTemplates::DiskFill.new(
          test_name,
          "#{chaos_experiment_name}",
          app_namespace,
          "#{spec_labels.first_key}",
          "#{spec_labels.first_value}"
        ).to_s
        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(test_name, chaos_experiment_name, disk_fill_time, args, namespace: app_namespace)
        test_passed = LitmusManager.check_chaos_verdict(chaos_result_name, chaos_experiment_name, args, namespace: app_namespace)
      end
      test_passed
    end
    if task_response
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "disk_fill chaos test passed")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "disk_fill chaos test failed")
    end
  end
end

desc "Does the CNF crash when pod-delete occurs"
task "pod_delete", ["install_litmus"] do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    #todo clear all annotations
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      app_namespace = resource[:namespace] || config.cnf_config[:helm_install_namespace]
      spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"])
      if spec_labels.as_h? && spec_labels.as_h.size > 0
        test_passed = true
      else
        stdout_failure("No resource label found for #{t.name} test for resource: #{resource["kind"]}/#{resource["name"]} in #{resource["namespace"]} namespace")
        test_passed = false
      end

      current_pod_key = ""
      current_pod_value = ""
      if args.named["pod_labels"]?
          pod_label = args.named["pod_labels"]?
          match_array = pod_label.to_s.split(",")

        test_passed = match_array.any? do |key_value|
          key, value = key_value.split("=")
          if spec_labels.as_h.has_key?(key) && spec_labels[key] == value
            current_pod_key = key
            current_pod_value = value
            puts "Match found for key: #{key} and value: #{value}"
            true
          else
            puts "Match not found for key: #{key} and value: #{value}"
            false
          end
        end
      end

      Log.info { "Spec Hash: #{args.named["pod_labels"]?}" }


      if test_passed
        Log.info { "Running for: #{spec_labels}"}
        puts "Running for: #{spec_labels}"
        Log.info { "Spec Hash: #{args.named["pod_labels"]?}" }
        puts "Spec Hash: #{args.named["pod_labels"]?}" 
        if args.named["offline"]?
          Log.info { "install resilience offline mode" }
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/pod-delete-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-delete-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-delete-rbac.yaml")
        else
          # experiment_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-delete/experiment.yaml"
          experiment_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-delete/experiment.yaml"
          experiment_path = LitmusManager.download_template(experiment_url, "#{t.name}_experiment.yaml")

          # rbac_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-delete/rbac.yaml"
          rbac_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-delete/rbac.yaml"
          rbac_path = LitmusManager.download_template(rbac_url, "#{t.name}_rbac.yaml")
          rbac_yaml = File.read(rbac_path)
          rbac_yaml = rbac_yaml.gsub("namespace: default", "namespace: #{app_namespace}")
          File.write(rbac_path, rbac_yaml)

          KubectlClient::Apply.file(experiment_path, namespace: app_namespace)
          KubectlClient::Apply.file(rbac_path)
        end

        Log.info { "resource: #{resource["name"]}" }
        KubectlClient::Annotate.run("--overwrite -n #{app_namespace} deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-delete"
        total_chaos_duration = "30"
        target_pod_name = ""
        test_name = "#{resource["name"]}-#{Random.rand(99)}" 
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        # spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"]).as_h
      if args.named["pod_labels"]?
        template = ChaosTemplates::PodDelete.new(
          test_name,
          "#{chaos_experiment_name}",
          app_namespace,
          "#{current_pod_key}",
          "#{current_pod_value}",
          total_chaos_duration,
          target_pod_name
        ).to_s
      else
        template = ChaosTemplates::PodDelete.new(
          test_name,
          "#{chaos_experiment_name}",
          app_namespace,
          "#{spec_labels.as_h.first_key}",
          "#{spec_labels.as_h.first_value}",
          total_chaos_duration,
          target_pod_name
        ).to_s
      end

        puts "template: #{template}"
        Log.info { "template: #{template}" }

        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args, namespace: app_namespace)
      end
      test_passed=LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args, namespace: app_namespace)
    end
    unless args.named["pod_labels"]?
        if task_response
          CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "pod_delete chaos test passed")
        else
          CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "pod_delete chaos test failed")
        end
    end
  end
end

desc "Does the CNF crash when pod-memory-hog occurs"
task "pod_memory_hog", ["install_litmus"] do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      app_namespace = resource[:namespace] || config.cnf_config[:helm_install_namespace]
      spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"])
      if spec_labels.as_h? && spec_labels.as_h.size > 0
        test_passed = true
      else
        stdout_failure("No resource label found for #{t.name} test for resource: #{resource["kind"]}/#{resource["name"]} in #{resource["namespace"]} namespace")
        test_passed = false
      end
      if test_passed
        if args.named["offline"]?
          Log.info { "install resilience offline mode" }
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/pod-memory-hog-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-memory-hog-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-memory-hog-rbac.yaml")
        else
          # experiment_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-memory-hog/experiment.yaml"
          experiment_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-memory-hog/experiment.yaml"
          # rbac_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-memory-hog/rbac.yaml"
          rbac_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-memory-hog/rbac.yaml"

          experiment_path = LitmusManager.download_template(experiment_url, "#{t.name}_experiment.yaml")
          KubectlClient::Apply.file(experiment_path, namespace: app_namespace)

          rbac_path = LitmusManager.download_template(rbac_url, "#{t.name}_rbac.yaml")
          rbac_yaml = File.read(rbac_path)
          rbac_yaml = rbac_yaml.gsub("namespace: default", "namespace: #{app_namespace}")
          File.write(rbac_path, rbac_yaml)
          KubectlClient::Apply.file(rbac_path)
        end
        KubectlClient::Annotate.run("--overwrite -n #{app_namespace} deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-memory-hog"
        total_chaos_duration = "60"
        target_pod_name = ""
        test_name = "#{resource["name"]}-#{Random.rand(99)}" 
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"]).as_h
        template = ChaosTemplates::PodMemoryHog.new(
          test_name,
          "#{chaos_experiment_name}",
          app_namespace,
          "#{spec_labels.first_key}",
          "#{spec_labels.first_value}",
          total_chaos_duration,
          target_pod_name
        ).to_s

        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args, namespace: app_namespace)
        test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args, namespace: app_namespace)
      end
      test_passed
    end
    if task_response
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "pod_memory_hog chaos test passed")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "pod_memory_hog chaos test failed")
    end
  end
end

desc "Does the CNF crash when pod-io-stress occurs"
task "pod_io_stress", ["install_litmus"] do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      app_namespace = resource[:namespace] || config.cnf_config[:helm_install_namespace]
      spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"])
      if spec_labels.as_h? && spec_labels.as_h.size > 0
        test_passed = true
      else
        stdout_failure("No resource label found for #{t.name} test for resource: #{resource["name"]} in #{resource["namespace"]}")
        test_passed = false
      end
      if test_passed
        if args.named["offline"]?
          Log.info { "install resilience offline mode" }
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/pod-io-stress-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-io-stress-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-io-stress-rbac.yaml")
        else
          # experiment_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-io-stress/experiment.yaml"
          experiment_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-io-stress/experiment.yaml"
          # rbac_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-io-stress/rbac.yaml"
          rbac_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-io-stress/rbac.yaml"

          experiment_path = LitmusManager.download_template(experiment_url, "#{t.name}_experiment.yaml")
          KubectlClient::Apply.file(experiment_path, namespace: app_namespace)

          rbac_path = LitmusManager.download_template(rbac_url, "#{t.name}_rbac.yaml")
          rbac_yaml = File.read(rbac_path)
          rbac_yaml = rbac_yaml.gsub("namespace: default", "namespace: #{app_namespace}")
          File.write(rbac_path, rbac_yaml)
          KubectlClient::Apply.file(rbac_path)
        end
        KubectlClient::Annotate.run("--overwrite -n #{app_namespace} deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-io-stress"
        total_chaos_duration = "120"
        target_pod_name = ""
        chaos_test_name = "#{resource["name"]}-#{Random.rand(99)}" 
        chaos_result_name = "#{chaos_test_name}-#{chaos_experiment_name}"

        spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"]).as_h
        template = ChaosTemplates::PodIoStress.new(
          chaos_test_name,
          "#{chaos_experiment_name}",
          app_namespace,
          "#{spec_labels.first_key}",
          "#{spec_labels.first_value}",
          total_chaos_duration,
          target_pod_name
        ).to_s

        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(chaos_test_name,chaos_experiment_name,total_chaos_duration,args, namespace: app_namespace)
        test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args, namespace: app_namespace)
      end
    end
    if task_response
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "pod_io_stress chaos test passed")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "pod_io_stress chaos test failed")
    end
  end
ensure
  # This ensures that no litmus-related resources are left behind after the test is run.
  # Only the default namespace is cleaned up.
  KubectlClient::Delete.command("all", {"app.kubernetes.io/part-of" => "litmus"})
end


desc "Does the CNF crash when pod-dns-error occurs"
task "pod_dns_error", ["install_litmus"] do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    runtimes = KubectlClient::Get.container_runtimes
    Log.info { "pod_dns_error runtimes: #{runtimes}" }
    if runtimes.find{|r| r.downcase.includes?("docker")}
      task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
        app_namespace = resource[:namespace] || config.cnf_config[:helm_install_namespace]
        spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"])
        if spec_labels.as_h? && spec_labels.as_h.size > 0
          test_passed = true
        else
          stdout_failure("No resource label found for #{t.name} test for resource: #{resource["kind"]}/#{resource["name"]} in #{resource["namespace"]} namespace")
          test_passed = false
        end
        if test_passed
          if args.named["offline"]?
              Log.info { "install resilience offline mode" }
            AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/pod-dns-error-experiment.yaml")
            KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-dns-error-experiment.yaml")
            KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-dns-error-rbac.yaml")
          else
            # experiment_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-dns-error/experiment.yaml"
            experiment_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-dns-error/experiment.yaml"
            # rbac_url = "https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-dns-error/rbac.yaml"
            rbac_url = "https://raw.githubusercontent.com/litmuschaos/chaos-charts/#{LitmusManager::Version}/charts/generic/pod-dns-error/rbac.yaml"

            experiment_path = LitmusManager.download_template(experiment_url, "#{t.name}_experiment.yaml")
            KubectlClient::Apply.file(experiment_path, namespace: app_namespace)

            rbac_path = LitmusManager.download_template(rbac_url, "#{t.name}_rbac.yaml")
            rbac_yaml = File.read(rbac_path)
            rbac_yaml = rbac_yaml.gsub("namespace: default", "namespace: #{app_namespace}")
            File.write(rbac_path, rbac_yaml)
            KubectlClient::Apply.file(rbac_path)
          end
          KubectlClient::Annotate.run("--overwrite -n #{app_namespace} deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

          chaos_experiment_name = "pod-dns-error"
          total_chaos_duration = "120"
          target_pod_name = ""
          test_name = "#{resource["name"]}-#{Random.rand(99)}" 
          chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

          spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"]).as_h
          template = ChaosTemplates::PodDnsError.new(
            test_name,
            "#{chaos_experiment_name}",
            app_namespace,
            "#{spec_labels.first_key}",
            "#{spec_labels.first_value}",
            total_chaos_duration,
          ).to_s

          File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
          KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
          LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args, namespace: app_namespace)
          test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args, namespace: app_namespace)
        end
      end
      if task_response
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "pod_dns_error chaos test passed")
      else
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "pod_dns_error chaos test failed")
      end
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Skipped, "pod_dns_error docker runtime not found")
    end
  end
end
