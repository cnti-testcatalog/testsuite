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
end

desc "Is there a liveness entry in the helm chart?"
task "liveness" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("liveness").info { "Starting test" }
    Log.for("liveness").debug { "cnf_config: #{config}" }
    resp = ""
    emoji_probe="⎈🧫"
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
      resource_ref = "#{resource[:kind]}/#{resource[:name]}"
      begin
        Log.for("liveness").debug { container.as_h["name"].as_s } if check_verbose(args)
        container.as_h["livenessProbe"].as_h
      rescue ex
        Log.for("liveness").error { ex.message } if check_verbose(args)
        test_passed = false
        stdout_failure("No livenessProbe found for container #{container.as_h["name"].as_s} part of #{resource_ref} in #{resource[:namespace]} namespace")
      end
      Log.for("liveness").info { "Resource #{resource_ref} passed liveness?: #{test_passed}" }
      test_passed
    end
    Log.for("liveness").info { "Workload resource task response: #{task_response}" }
    if task_response
      resp = upsert_passed_task("liveness","✔️  🏆 PASSED: Helm liveness probe found #{emoji_probe}")
		else
			resp = upsert_failed_task("liveness","✖️  🏆 FAILED: No livenessProbe found #{emoji_probe}")
    end
    resp
  end
end

desc "Is there a readiness entry in the helm chart?"
task "readiness" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("readiness").info { "Starting test" }
    Log.for("readiness").debug { "cnf_config: #{config}" }
    resp = ""
    emoji_probe="⎈🧫"
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
      resource_ref = "#{resource[:kind]}/#{resource[:name]}"
      begin
        Log.for("readiness").debug { container.as_h["name"].as_s } if check_verbose(args)
        container.as_h["readinessProbe"].as_h
      rescue ex
        Log.for("readiness").error { ex.message } if check_verbose(args)
        test_passed = false
        stdout_failure("No readinessProbe found for container #{container.as_h["name"].as_s} part of #{resource_ref} in #{resource[:namespace]} namespace")
      end
      Log.for("readiness").info { "Resource #{resource_ref} passed liveness?: #{test_passed}" }
      test_passed
    end
    Log.for("readiness").info { "Workload resource task response: #{task_response}" }
    if task_response
      resp = upsert_passed_task("readiness","✔️  🏆 PASSED: Helm readiness probe found #{emoji_probe}")
		else
      resp = upsert_failed_task("readiness","✖️  🏆 FAILED: No readinessProbe found #{emoji_probe}")
    end
    resp
  end
end


desc "Does the CNF crash when network latency occurs"
task "pod_network_latency", ["install_litmus"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "pod_network_latency" } if check_verbose(args)
    Log.debug { "cnf_config: #{config}" }
    #TODO tests should fail if cnf not installed
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      Log.info { "Current Resource Name: #{resource["name"]} Type: #{resource["kind"]}" }
      if KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h? && KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.size > 0 && resource["kind"] == "Deployment"
        test_passed = true
      else
        puts "Resource is not a Deployment or no resource label was found for resource: #{resource["name"]}".colorize(:red)
        test_passed = false
      end
      if test_passed
        if args.named["offline"]?
          Log.info { "install resilience offline mode" }
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/lat-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/lat-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/lat-rbac.yaml")
        else
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-latency/experiment.yaml")
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-latency/rbac.yaml")
        end
        KubectlClient::Annotate.run("--overwrite deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-network-latency"
        total_chaos_duration = "60"
        test_name = "#{resource["name"]}-#{Random.rand(99)}"
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        template = ChaosTemplates::PodNetworkLatency.new(
          test_name,
          "#{chaos_experiment_name}",
          "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}",
          "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}",
          total_chaos_duration
        ).to_s
        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args)
        test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args)
      end
    end
    if task_response
      resp = upsert_passed_task("pod_network_latency","✔️  PASSED: pod_network_latency chaos test passed 🗡️💀♻️")
    else
      resp = upsert_failed_task("pod_network_latency","✖️  FAILED: pod_network_latency chaos test failed 🗡️💀♻️")
    end
  end
end

desc "Does the CNF crash when network corruption occurs"
task "pod_network_corruption", ["install_litmus"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info {"pod_network_corruption" if check_verbose(args)}
    LOGGING.debug "cnf_config: #{config}"
    #TODO tests should fail if cnf not installed
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      Log.info {"Current Resource Name: #{resource["name"]} Type: #{resource["kind"]}"}
      if KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h? && KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.size > 0 && resource["kind"] == "Deployment"
        test_passed = true
      else
        puts "Resource is not a Deployment or no resource label was found for resource: #{resource["name"]}".colorize(:red)
        test_passed = false
      end
      if test_passed
        if args.named["offline"]?
          Log.info {"install resilience offline mode"}
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/corr-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/corr-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/corr-rbac.yaml")
        else
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-corruption/experiment.yaml")
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-corruption/rbac.yaml")
        end
        KubectlClient::Annotate.run("--overwrite deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-network-corruption"
        total_chaos_duration = "60"
        test_name = "#{resource["name"]}-#{Random.rand(99)}"
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        template = ChaosTemplates::PodNetworkCorruption.new(
          test_name,
          "#{chaos_experiment_name}",
          "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}",
          "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}",
          total_chaos_duration
        ).to_s
        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args)
        test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args)
      end
    end
    if task_response
      resp = upsert_passed_task("pod_network_corruption","✔️  PASSED: pod_network_corruption chaos test passed 🗡️💀♻️")
    else
      resp = upsert_failed_task("pod_network_corruption","✖️  FAILED: pod_network_corruption chaos test failed 🗡️💀♻️")
    end
  end
end

desc "Does the CNF crash when network duplication occurs"
task "pod_network_duplication", ["install_litmus"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info {"pod_network_duplication"} if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"
    #TODO tests should fail if cnf not installed
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      Log.info{ "Current Resource Name: #{resource["name"]} Type: #{resource["kind"]}"}
      if KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h? && KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.size > 0 && resource["kind"] == "Deployment"
        test_passed = true
      else
        puts "Resource is not a Deployment or no resource label was found for resource: #{resource["name"]}".colorize(:red)
        test_passed = false
      end
      if test_passed
        if args.named["offline"]?
          Log.info {"install resilience offline mode"}
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/dup-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/dup-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/dup-rbac.yaml")
        else
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-duplication/experiment.yaml")
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-duplication/rbac.yaml")
        end
        KubectlClient::Annotate.run("--overwrite deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-network-duplication"
        total_chaos_duration = "60"
        test_name = "#{resource["name"]}-#{Random.rand(99)}"
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        template = ChaosTemplates::PodNetworkDuplication.new(
          test_name,
          "#{chaos_experiment_name}",
          "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}",
          "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}",
          total_chaos_duration
        ).to_s
        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args)
        test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args)
      end
    end
    if task_response
      resp = upsert_passed_task("pod_network_duplication","✔️  PASSED: pod_network_duplication chaos test passed 🗡️💀♻️")
    else
      resp = upsert_failed_task("pod_network_duplication","✖️  FAILED: pod_network_duplication chaos test failed 🗡️💀♻️")
    end
  end
end

desc "Does the CNF crash when disk fill occurs"
task "disk_fill", ["install_litmus"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "disk_fill" } if check_verbose(args)
    Log.debug { "cnf_config: #{config}" }
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      app_namespace = resource[:namespace] || config.cnf_config[:helm_install_namespace]
      spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"])
      if spec_labels.as_h? && spec_labels.as_h.size > 0
        test_passed = true
      else
        stdout_failure("No resource label found for disk_fill test for resource: #{resource["kind"]}/#{resource["name"]} in #{resource["namespace"]} namespace")
        test_passed = false
      end
      if test_passed
        if args.named["offline"]?
          Log.info { "install resilience offline mode" }
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/disk-fill-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/disk-fill-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/disk-fill-rbac.yaml")
        else
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/disk-fill/experiment.yaml")
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/disk-fill/rbac.yaml")
        end
        KubectlClient::Annotate.run("--overwrite -n #{app_namespace} deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "disk-fill"
        disk_fill_time = "100"
        test_name = "#{resource["name"]}-#{Random.rand(99)}" 
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"]).as_h
        Log.for("disk_fill:spec_labels").info { "Spec labels for chaos template. Key: #{spec_labels.first_key}; Value: #{spec_labels.first_value}" }
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
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,disk_fill_time,args)
      end
      test_passed=LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args)
    end
    if task_response 
      resp = upsert_passed_task("disk_fill","✔️  PASSED: disk_fill chaos test passed 🗡️💀♻️")
    else
      resp = upsert_failed_task("disk_fill","✖️  FAILED: disk_fill chaos test failed 🗡️💀♻️")
    end
  end
end

desc "Does the CNF crash when pod-delete occurs"
task "pod_delete", ["install_litmus"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "pod_delete" } if check_verbose(args)
    Log.debug { "cnf_config: #{config}" }
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      app_namespace = resource[:namespace] || config.cnf_config[:helm_install_namespace]
      spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"])
      if spec_labels.as_h? && spec_labels.as_h.size > 0
        test_passed = true
      else
        stdout_failure("No resource label found for pod_delete test for resource: #{resource["kind"]}/#{resource["name"]} in #{resource["namespace"]} namespace")
        test_passed = false
      end
      if test_passed
        if args.named["offline"]?
          Log.info { "install resilience offline mode" }
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/pod-delete-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-delete-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-delete-rbac.yaml")
        else
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-delete/experiment.yaml")
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-delete/rbac.yaml")
        end
        KubectlClient::Annotate.run("--overwrite -n #{app_namespace} deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-delete"
        total_chaos_duration = "30"
        target_pod_name = ""
        test_name = "#{resource["name"]}-#{Random.rand(99)}" 
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        spec_labels = KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"], resource["namespace"]).as_h
        template = ChaosTemplates::PodDelete.new(
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
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args)
      end
      test_passed=LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args)
    end
    if task_response
      resp = upsert_passed_task("pod_delete","✔️  PASSED: pod_delete chaos test passed 🗡️💀♻️")
    else
      resp = upsert_failed_task("pod_delete","✖️  FAILED: pod_delete chaos test failed 🗡️💀♻️")
    end
  end
end

desc "Does the CNF crash when pod-memory-hog occurs"
task "pod_memory_hog", ["install_litmus"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "pod_memory_hog" } if check_verbose(args)
    Log.debug { "cnf_config: #{config}" }
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      if KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h? && KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.size > 0
        test_passed = true
      else
        puts "No resource label found for pod_memory_hog test for resource: #{resource["name"]}".colorize(:red)
        test_passed = false
      end
      if test_passed
        if args.named["offline"]?
          Log.info { "install resilience offline mode" }
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/pod-memory-hog-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-memory-hog-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-memory-hog-rbac.yaml")
        else
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-memory-hog/experiment.yaml")
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-memory-hog/rbac.yaml")
        end
        KubectlClient::Annotate.run("--overwrite deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-memory-hog"
        total_chaos_duration = "60"
        target_pod_name = ""
        test_name = "#{resource["name"]}-#{Random.rand(99)}" 
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        template = ChaosTemplates::PodMemoryHog.new(
          test_name,
          "#{chaos_experiment_name}",
          "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}",
          "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}",
          total_chaos_duration,
          target_pod_name
        ).to_s

        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args)
        test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args)
      end
    end
    if task_response
      resp = upsert_passed_task("pod_memory_hog","✔️  PASSED: pod_memory_hog chaos test passed 🗡️💀♻️")
    else
      resp = upsert_failed_task("pod_memory_hog","✖️  FAILED: pod_memory_hog chaos test failed 🗡️💀♻️")
    end
  end
end

desc "Does the CNF crash when pod-io-stress occurs"
task "pod_io_stress", ["install_litmus"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "pod_io_stress" } if check_verbose(args)
    Log.debug { "cnf_config: #{config}" }
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      if KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h? && KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.size > 0
        test_passed = true
      else
        puts "No resource label found for pod_io_stress test for resource: #{resource["name"]}".colorize(:red)
        test_passed = false
      end
      if test_passed
        if args.named["offline"]?
          Log.info { "install resilience offline mode" }
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/pod-io-stress-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-io-stress-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-io-stress-rbac.yaml")
        else
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-io-stress/experiment.yaml")
          KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-io-stress/rbac.yaml")
        end
        KubectlClient::Annotate.run("--overwrite deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-io-stress"
        total_chaos_duration = "120"
        target_pod_name = ""
        test_name = "#{resource["name"]}-#{Random.rand(99)}" 
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        template = ChaosTemplates::PodIoStress.new(
          test_name,
          "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}",
          "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}",
          "#{chaos_experiment_name}",
          total_chaos_duration,
          target_pod_name
        ).to_s

        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args)
        test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args)
      end
    end
    if task_response
      resp = upsert_passed_task("pod_io_stress","✔️  PASSED: pod_io_stress chaos test passed 🗡️💀♻️")
    else
      resp = upsert_failed_task("pod_io_stress","✖️  FAILED: pod_io_stress chaos test failed 🗡️💀♻️")
    end
  end
ensure
  # This ensures that no litmus-related resources are left behind after the test is run.
  # Only the default namespace is cleaned up.
  KubectlClient::Delete.command("all", {"app.kubernetes.io/part-of" => "litmus"})
end


desc "Does the CNF crash when pod-dns-error occurs"
task "pod_dns_error", ["install_litmus"] do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "pod_dns_error" } if check_verbose(args)
    Log.debug { "cnf_config: #{config}" }
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    runtimes = KubectlClient::Get.container_runtimes
    Log.info { "pod_dns_error runtimes: #{runtimes}" }
    if runtimes.find{|r| r.downcase.includes?("docker")}
      task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
        if KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h? && KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.size > 0
          test_passed = true
        else
          puts "No resource label found for pod_dns_error test for resource: #{resource["name"]}".colorize(:red)
          test_passed = false
        end
        if test_passed
          if args.named["offline"]?
              Log.info { "install resilience offline mode" }
            AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/pod-dns-error-experiment.yaml")
            KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-dns-error-experiment.yaml")
            KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/pod-dns-error-rbac.yaml")
          else
            KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-dns-error/experiment.yaml")
            KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-dns-error/rbac.yaml")
          end
          KubectlClient::Annotate.run("--overwrite deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

          chaos_experiment_name = "pod-dns-error"
          total_chaos_duration = "120"
          target_pod_name = ""
          test_name = "#{resource["name"]}-#{Random.rand(99)}" 
          chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

          template = ChaosTemplates::PodDnsError.new(
            test_name,
            "#{chaos_experiment_name}",
            "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}",
            "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}",
            total_chaos_duration,
          ).to_s

          File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
          KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
          LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args)
          test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args)
        end
      end
      if task_response
        resp = upsert_passed_task("pod_dns_error","✔️  PASSED: pod_dns_error chaos test passed 🗡️💀♻️")
      else
        resp = upsert_failed_task("pod_dns_error","✖️  FAILED: pod_dns_error chaos test failed 🗡️💀♻️")
      end
    else
      resp = upsert_skipped_task("pod_dns_error","⏭️  SKIPPED: pod_dns_error docker runtime not found 🗡️💀♻️")
    end
  end
end
