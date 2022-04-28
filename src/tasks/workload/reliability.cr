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
    VERBOSE_LOGGING.info "liveness" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"
    resp = ""
    emoji_probe="⎈🧫"
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
      begin
        VERBOSE_LOGGING.debug container.as_h["name"].as_s if check_verbose(args)
        container.as_h["livenessProbe"].as_h
      rescue ex
        VERBOSE_LOGGING.error ex.message if check_verbose(args)
        test_passed = false
        puts "No livenessProbe found for resource: #{resource} and container: #{container.as_h["name"].as_s}".colorize(:red)
      end
      LOGGING.debug "liveness test_passed: #{test_passed}"
      test_passed
    end
    LOGGING.debug "liveness task response: #{task_response}"
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
    LOGGING.debug "cnf_config: #{config}"
    VERBOSE_LOGGING.info "readiness" if check_verbose(args)
    # Parse the cnf-testsuite.yml
    resp = ""
    emoji_probe="⎈🧫"
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
      begin
        VERBOSE_LOGGING.debug container.as_h["name"].as_s if check_verbose(args)
        container.as_h["readinessProbe"].as_h
      rescue ex
        VERBOSE_LOGGING.error ex.message if check_verbose(args)
        test_passed = false
        puts "No readinessProbe found for resource: #{resource} and container: #{container.as_h["name"].as_s}".colorize(:red)
      end
      test_passed
    end
    if task_response
      resp = upsert_passed_task("readiness","✔️  🏆 PASSED: Helm readiness probe found #{emoji_probe}")
		else
      resp = upsert_failed_task("readiness","✖️  🏆 FAILED: No readinessProbe found #{emoji_probe}")
    end
    resp
  end
end

#desc "Does the CNF crash when network loss occurs"
#task "chaos_network_loss", ["install_chaosmesh"] do |_, args|
#  CNFManager::Task.task_runner(args) do |args, config|
#    Log.for("verbose").info { "chaos_network_loss" } if check_verbose(args)
#    Log.debug { "cnf_config: #{config}" }
#    emoji_chaos_network_loss="📶☠️"
#    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
#    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
#
#      if KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h? &&
#          KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.size > 0
#        test_passed = true
#      else
#        puts "No resource label found for container kill test for resource: #{resource}".colorize(:red)
#        test_passed = false
#      end
#
#      if test_passed
#        template = ChaosTemplates::Network.new(
#                     KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h
#                   ).to_s
#        File.write("#{destination_cnf_dir}/chaos_network_loss.yml", template)
#        run_chaos = KubectlClient::Apply.file("#{destination_cnf_dir}/chaos_network_loss.yml")
#        Log.for("verbose").debug { "#{run_chaos[:output]}" } if check_verbose(args)
#        if ChaosMeshSetup.wait_for_test("NetworkChaos", "network-loss")
#          Log.info { "Wait Done" }
#          unless KubectlClient::Get.resource_desired_is_available?(resource["kind"].as_s, resource["name"].as_s)
#            test_passed = false
#            puts "Replicas did not return desired count after network chaos test for resource: #{resource["name"]}".colorize(:red)
#          end
#        else
#          # TODO Change this to an exception (points = 0)
#          # Add SKIPPED to points.yml and set to points = 0
#          # e.g. upsert_exception_task
#          test_passed = false
#          puts "Chaosmesh failed to finish for resource: #{resource["name"]}".colorize(:red)
#        end
#      end
#      test_passed
#    end
#    if task_response
#      resp = upsert_passed_task("chaos_network_loss","✔️  PASSED: Replicas available match desired count after network chaos test #{emoji_chaos_network_loss}")
#    else
#      resp = upsert_failed_task("chaos_network_loss","✖️  FAILED: Replicas did not return desired count after network chaos test #{emoji_chaos_network_loss}")
#    end
#  ensure
#    KubectlClient::Delete.file("#{destination_cnf_dir}/chaos_network_loss.yml")
#  end
#end

# desc "Does the CNF crash when CPU usage is high"
# task "chaos_cpu_hog", ["install_chaosmesh"] do |_, args|
#   CNFManager::Task.task_runner(args) do |args, config|
#     Log.for("verbose").info { "chaos_cpu_hog" } if check_verbose(args)
#     Log.debug { "cnf_config: #{config}" }
#     destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
#     emoji_chaos_cpu_hog="📦💻🐷📈"
#     task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
#       if KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h? && KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.size > 0
#         test_passed = true
#       else
#         puts "No resource label found for container kill test for resource: #{resource["name"]}".colorize(:red)
#         test_passed = false
#       end
#       if test_passed
#         template = ChaosTemplates::Cpu.new(
#                      KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h
#                    ).to_s
#         File.write("#{destination_cnf_dir}/chaos_cpu_hog.yml", template)
#         run_chaos = KubectlClient::Apply.file("#{destination_cnf_dir}/chaos_cpu_hog.yml")
#         Log.for("verbose").debug { "#{run_chaos[:output]}" } if check_verbose(args)
#         # TODO fail if exceeds
#         if ChaosMeshSetup.wait_for_test("StressChaos", "burn-cpu")
#           unless KubectlClient::Get.resource_desired_is_available?(resource["kind"].as_s, resource["name"].as_s)
#             test_passed = false
#             puts "Chaosmesh Application pod is not healthy after high CPU consumption for resource: #{resource["name"]}".colorize(:red)
#           end
#         else
#           # TODO Change this to an exception (points = 0)
#           # TODO Add SKIPPED to points.yml and set to points = 0
#           # e.g. upsert_exception_task
#             test_passed = false
#             puts "Chaosmesh failed to finish for resource: #{resource["name"]}".colorize(:red)
#         end
#       end
#       test_passed
#     end
#     if task_response
#       resp = upsert_passed_task("chaos_cpu_hog","✔️  PASSED: Application pod is healthy after high CPU consumption #{emoji_chaos_cpu_hog}")
#     else
#       resp = upsert_failed_task("chaos_cpu_hog","✖️  FAILED: Application pod is not healthy after high CPU consumption #{emoji_chaos_cpu_hog}")
#     end
#   ensure
#     KubectlClient::Delete.file("#{destination_cnf_dir}/chaos_cpu_hog.yml")
#   end
# end

# desc "Does the CNF recover when its container is killed"
# task "chaos_container_kill", ["install_chaosmesh"] do |_, args|
#   CNFManager::Task.task_runner(args) do |args, config|
#     Log.for("verbose").info { "chaos_container_kill" } if check_verbose(args)
#     Log.debug { "cnf_config: #{config}" }
#     destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
#     emoji_chaos_container_kill="🗡️💀♻️"
#     resource_names = [] of Hash(String, String)
#     task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|

#       if KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h? &&
#           KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.size > 0
#         test_passed = true
#       else
#         puts "No resource label found for container kill test for resource: #{resource}".colorize(:red)
#         test_passed = false
#       end
#       if test_passed
#         # TODO change helm_chart_container_name to container_name
#         template = ChaosTemplates::ContainerKill.new(
#                      "#{container.as_h["name"]}"
#                      KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h
#         ).to_s
#         Log.debug { "chaos template: #{template}" }
#         File.write("#{destination_cnf_dir}/chaos_container_kill.yml", template)
#         run_chaos = KubectlClient::Apply.file("#{destination_cnf_dir}/chaos_container_kill.yml")
#         Log.for("verbose").debug { "#{run_chaos[:output]}" } if check_verbose(args)
#         if ChaosMeshSetup.wait_for_test("PodChaos", "container-kill")
#           KubectlClient::Get.resource_wait_for_install(resource["kind"].as_s, resource["name"].as_s, wait_count=60)
#         else
#           # TODO Change this to an exception (points = 0)
#           # TODO Add SKIPPED to points.yml and set to points = 0
#           # e.g. upsert_exception_task
#           test_passed = false
#           puts "Chaosmesh chaos_container_kill failed to finish for resource: #{resource} and container: #{container.as_h["name"].as_s}".colorize(:red)
#         end
#       end

#       resource_names << {"kind" => resource["kind"].as_s,
#                          "name" => resource["name"].as_s}
#       test_passed
#     end
#     desired_passed = resource_names.map do |x|
#       if KubectlClient::Get.resource_desired_is_available?(x["kind"], x["name"])
#         true
#       else
#         puts "Replicas did not return desired count after container kill test for resource: #{x}".colorize(:red)
#         false
#       end
#     end
#     if task_response && desired_passed.all?
#       resp = upsert_passed_task("chaos_container_kill","✔️  PASSED: Replicas available match desired count after container kill test #{emoji_chaos_container_kill}")
#     else
#       resp = upsert_failed_task("chaos_container_kill","✖️  FAILED: Replicas did not return desired count after container kill test #{emoji_chaos_container_kill}")
#     end
#   ensure
#     KubectlClient::Delete.file("#{destination_cnf_dir}/chaos_container_kill.yml")
#   end
# end

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
      if KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h? && KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.size > 0
        test_passed = true
      else
        puts "No resource label found for disk_fill test for resource: #{resource["name"]}".colorize(:red)
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
        KubectlClient::Annotate.run("--overwrite deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "disk-fill"
        disk_fill_time = "100"
        test_name = "#{resource["name"]}-#{Random.rand(99)}" 
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        # todo change to use all labels instead of first label
        template = ChaosTemplates::DiskFill.new(
          test_name,
          "#{chaos_experiment_name}",
          "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}",
          "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}"
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
      if KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h? && KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.size > 0
        test_passed = true
      else
        puts "No resource label found for pod_delete test for resource: #{resource["name"]}".colorize(:red)
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
        KubectlClient::Annotate.run("--overwrite deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")

        chaos_experiment_name = "pod-delete"
        total_chaos_duration = "30"
        target_pod_name = ""
        test_name = "#{resource["name"]}-#{Random.rand(99)}" 
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        template = ChaosTemplates::PodDelete.new(
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

class ChaosTemplates
  class PodIoStress
    def initialize(
      @test_name : String,
      @deployment_label : String,
      @deployment_label_value : String,
      @chaos_experiment_name : String,
      @total_chaos_duration : String,
      @target_pod_name : String
    )
    end
    ECR.def_to_s("src/templates/chaos_templates/pod_io_stress.yml.ecr")
  end

  class Network
    def initialize(@labels)
    end
    ECR.def_to_s("src/templates/chaos_templates/network.yml.ecr")
  end

  class Cpu
    def initialize(@labels)
    end
    ECR.def_to_s("src/templates/chaos_templates/cpu.yml.ecr")
  end

  class ContainerKill
    def initialize(@helm_chart_container_name : String, @labels : Hash(String, String))
    end
    ECR.def_to_s("src/templates/chaos_templates/container_kill.yml.ecr")
  end

  class PodNetworkLatency
    def initialize(
      @test_name : String,
      @chaos_experiment_name : String,
      @deployment_label : String,
      @deployment_label_value : String,
      @total_chaos_duration : String
    )
    end
    ECR.def_to_s("src/templates/chaos_templates/pod_network_latency.yml.ecr")
  end

  class PodNetworkCorruption
    def initialize(
      @test_name : String,
      @chaos_experiment_name : String,
      @deployment_label : String,
      @deployment_label_value : String,
      @total_chaos_duration : String
    )
    end
    ECR.def_to_s("src/templates/chaos_templates/pod_network_corruption.yml.ecr")
  end

  class PodNetworkDuplication
    def initialize(
      @test_name : String,
      @chaos_experiment_name : String,
      @deployment_label : String,
      @deployment_label_value : String,
      @total_chaos_duration : String
    )
    end
    ECR.def_to_s("src/templates/chaos_templates/pod_network_duplication.yml.ecr")
  end

  class DiskFill
    def initialize(
      @test_name : String,
      @chaos_experiment_name : String,
      @deployment_label : String,
      @deployment_label_value : String
    )
    end
    ECR.def_to_s("src/templates/chaos_templates/disk_fill.yml.ecr")
  end

  class PodDelete
    def initialize(
      @test_name : String,
      @chaos_experiment_name : String,
      @deployment_label : String,
      @deployment_label_value : String,
      @total_chaos_duration : String,
      @target_pod_name : String
    )
    end
    ECR.def_to_s("src/templates/chaos_templates/pod_delete.yml.ecr")
  end

  class PodMemoryHog
    def initialize(
      @test_name : String,
      @chaos_experiment_name : String,
      @deployment_label : String,
      @deployment_label_value : String,
      @total_chaos_duration : String,
      @target_pod_name : String
    )
    end
    ECR.def_to_s("src/templates/chaos_templates/pod_memory_hog.yml.ecr")
  end

  class NodeDrain
    def initialize(
      @test_name : String,
      @chaos_experiment_name : String,
      @deployment_label : String,
      @deployment_label_value : String,
      @total_chaos_duration : String,
      @app_nodename : String
    )
    end
    ECR.def_to_s("src/templates/chaos_templates/node_drain.yml.ecr")
  end

  class PodDnsError
    def initialize(
      @test_name : String,
      @chaos_experiment_name : String,
      @deployment_label : String,
      @deployment_label_value : String,
      @total_chaos_duration : String,
    )
    end
    ECR.def_to_s("src/templates/chaos_templates/pod_dns_error.yml.ecr")
  end
end
