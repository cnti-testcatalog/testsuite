# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "crinja"
require "../utils/utils.cr"

desc "The CNF test suite checks to see if the CNFs are resilient to failures."
 task "resilience", ["pod_network_latency","chaos_cpu_hog", "chaos_container_kill", "disk_fill", "pod_delete", "pod_memory_hog", "pod_io_stress", "node_drain"] do |t, args|
  Log.for("verbose").info {  "resilience" } if check_verbose(args)
  VERBOSE_LOGGING.debug "resilience args.raw: #{args.raw}" if check_verbose(args)
  VERBOSE_LOGGING.debug "resilience args.named: #{args.named}" if check_verbose(args)
  stdout_score("resilience")
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
#        template = Crinja.render(network_chaos_template, { "labels" => KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h })
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
#         template = Crinja.render(cpu_chaos_template, { "labels" => KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h })
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
#         template = Crinja.render(chaos_template_container_kill, { "labels" => KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h, "helm_chart_container_name" => "#{container.as_h["name"]}" })
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

        template = Crinja.render(chaos_template_pod_network_latency, {"chaos_experiment_name"=> "#{chaos_experiment_name}", "deployment_label" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}", "deployment_label_value" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}", "test_name" => test_name,"total_chaos_duration" => total_chaos_duration})
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

        template = Crinja.render(chaos_template_pod_network_corruption, {"chaos_experiment_name"=> "#{chaos_experiment_name}", "deployment_label" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}", "deployment_label_value" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}", "test_name" => test_name,"total_chaos_duration" => total_chaos_duration})
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

        template = Crinja.render(chaos_template_pod_network_duplication, {"chaos_experiment_name"=> "#{chaos_experiment_name}", "deployment_label" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}", "deployment_label_value" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}", "test_name" => test_name,"total_chaos_duration" => total_chaos_duration})
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
        template = Crinja.render(chaos_template_disk_fill, {"chaos_experiment_name"=> "#{chaos_experiment_name}", "deployment_label" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}", "deployment_label_value" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}", "test_name" => test_name})
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

        template = Crinja.render(chaos_template_pod_delete, {"chaos_experiment_name"=> "#{chaos_experiment_name}", "deployment_label" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}", "deployment_label_value" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}", "test_name" => test_name,"target_pod_name" => target_pod_name,"total_chaos_duration" => total_chaos_duration})
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

        template = Crinja.render(chaos_template_pod_memory_hog, {"chaos_experiment_name"=> "#{chaos_experiment_name}", "deployment_label" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}", "deployment_label_value" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}", "test_name" => test_name,"target_pod_name" => target_pod_name,"total_chaos_duration" => total_chaos_duration})
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

        template = Crinja.render(chaos_template_pod_io_stress, {"chaos_experiment_name"=> "#{chaos_experiment_name}", "deployment_label" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}", "deployment_label_value" => "#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}", "test_name" => test_name,"target_pod_name" => target_pod_name,"total_chaos_duration" => total_chaos_duration})
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
end

desc "Does the CNF crash when node-drain occurs"
task "node_drain" do |t, args|
  CNFManager::Task.task_runner(args) do |args, config|
    skipped = false
    Log.for("verbose").info {"node_drain"} if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
    schedulable_nodes_count=KubectlClient::Get.schedulable_nodes_list
    if schedulable_nodes_count.size > 1
      if KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h? && KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.size > 0
        test_passed = true
      else
        puts "No resource label found for node_drain test for resource: #{resource["name"]}".colorize(:red)
        test_passed = false
      end
      if test_passed

        LitmusManager.cordon_target_node(args)
        LitmusManager.install_litmus(args)
        if args.named["offline"]?
          Log.info {"install resilience offline mode"}
          AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/node-drain-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/node-drain-experiment.yaml")
          KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/node-drain-rbac.yaml")
        else
          puts "No resource label found for node_drain test for resource: #{resource["name"]}".colorize(:red)
          test_passed = false
        end
        if test_passed
          if args.named["offline"]?
               Log.info {"install resilience offline mode"}
               AirGap.image_pull_policy("#{OFFLINE_MANIFESTS_PATH}/node-drain-experiment.yaml")
               KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/node-drain-experiment.yaml")
               KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/node-drain-rbac.yaml")
             else
               KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/node-drain/experiment.yaml")
               KubectlClient::Apply.file("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/node-drain/rbac.yaml")
          end
          KubectlClient::Annotate.run("--overwrite deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")
          deployment_label="#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}"
          deployment_label_value="#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}"

          app_nodeName_cmd = "kubectl get pods -l #{deployment_label}=#{deployment_label_value} -o=jsonpath='{.items[0].spec.nodeName}'"
          puts "Getting the app node name #{app_nodeName_cmd}" if check_verbose(args)
          status_code = Process.run("#{app_nodeName_cmd}", shell: true, output: appNodeName_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status
          puts "status_code: #{status_code}" if check_verbose(args)  
          app_nodeName = appNodeName_response.to_s

          chaos_experiment_name = "node-drain"
          total_chaos_duration = "90"
          test_name = "#{resource["name"]}-#{Random.rand(99)}" 
          chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

          template = Crinja.render(chaos_template_node_drain, {"chaos_experiment_name"=> "#{chaos_experiment_name}","deployment_label"=> "#{deployment_label}","deployment_label_value"=> "#{deployment_label_value}", "test_name" => test_name,"total_chaos_duration" => total_chaos_duration,"app_nodeName" => app_nodeName})
          File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
          KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
          LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args)
          test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args)
        end
        KubectlClient::Annotate.run("--overwrite deploy/#{resource["name"]} litmuschaos.io/chaos=\"true\"")
        deployment_label="#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_key}"
        deployment_label_value="#{KubectlClient::Get.resource_spec_labels(resource["kind"], resource["name"]).as_h.first_value}"
  
        app_nodeName_cmd = "kubectl get pods -l #{deployment_label}=#{deployment_label_value} -o=jsonpath='{.items[0].spec.nodeName}'"
        puts "Getting the app node name #{app_nodeName_cmd}" if check_verbose(args)
        status_code = Process.run("#{app_nodeName_cmd}", shell: true, output: appNodeName_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status
        puts "status_code: #{status_code}" if check_verbose(args)  
        app_nodeName = appNodeName_response.to_s
    
        chaos_experiment_name = "node-drain"
        total_chaos_duration = "90"
        test_name = "#{resource["name"]}-#{Random.rand(99)}" 
        chaos_result_name = "#{test_name}-#{chaos_experiment_name}"

        template = Crinja.render(chaos_template_node_drain, {"chaos_experiment_name"=> "#{chaos_experiment_name}","deployment_label"=> "#{deployment_label}","deployment_label_value"=> "#{deployment_label_value}", "test_name" => test_name,"total_chaos_duration" => total_chaos_duration,"app_nodeName" => app_nodeName})
        File.write("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml", template)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml")
        LitmusManager.wait_for_test(test_name,chaos_experiment_name,total_chaos_duration,args)
        test_passed = LitmusManager.check_chaos_verdict(chaos_result_name,chaos_experiment_name,args)
    end
    else
      skipped = true
    end
    end
    if task_response && skipped
      Log.for("verbose").warn{"The node_drain test needs minimum 2 schedulable nodes, current number of nodes: #{KubectlClient::Get.schedulable_nodes_list.size}"} if check_verbose(args)
      resp = upsert_skipped_task("node_drain","✖️  SKIPPED: node_drain chaos test skipped insufficient number of nodes🗡️💀♻️")
    elsif task_response
      resp = upsert_passed_task("node_drain","✔️  PASSED: node_drain chaos test passed 🗡️💀♻️")
    else
      resp = upsert_failed_task("node_drain","✖️  FAILED: node_drain chaos test failed 🗡️💀♻️")
    end
  end
end

def chaos_template_pod_io_stress
  <<-TEMPLATE
    apiVersion: litmuschaos.io/v1alpha1
    kind: ChaosEngine
    metadata:
      name: {{ test_name }}
      namespace: default
    spec:
      engineState: 'active'
      appinfo:
        appns: 'default'
        applabel: '{{ deployment_label}}={{ deployment_label_value }}'
        appkind: 'deployment'
      chaosServiceAccount: {{ chaos_experiment_name }}-sa
      experiments:
        - name: {{ chaos_experiment_name }}
          spec:
            components:
              env:
                # set chaos duration (in sec) as desired
                - name: TOTAL_CHAOS_DURATION
                  value: '{{ total_chaos_duration }}'
                  
                ## specify the size as percentage of free space on the file system
                - name: FILESYSTEM_UTILIZATION_PERCENTAGE
                  value: '50'
                - name: TARGET_PODS
                  value: '{{ target_pod_name }}'                  
    
                 ## provide the cluster runtime
                - name: CONTAINER_RUNTIME
                  value: 'containerd'   
    
                # provide the socket file path
                - name: SOCKET_PATH
                  value: '/run/containerd/containerd.sock'
  TEMPLATE
end

def network_chaos_template
  <<-TEMPLATE
  apiVersion: chaos-mesh.org/v1alpha1
  kind: NetworkChaos
  metadata:
    name: network-loss
    namespace: default
  spec:
    action: loss
    mode: one
    selector:
      labelSelectors:
        {% for label in labels %}
        '{{ label[0]}}': '{{ label[1] }}'
        {% endfor %}
    loss:
      loss: '100'
      correlation: '100'
    duration: '40s'
    scheduler:
      cron: '@every 600s'
  TEMPLATE
end

def cpu_chaos_template
  <<-TEMPLATE
  apiVersion: chaos-mesh.org/v1alpha1
  kind: StressChaos
  metadata:
    name: burn-cpu
    namespace: default
  spec:
    mode: one
    selector:
      labelSelectors:
        {% for label in labels %}
        '{{ label[0]}}': '{{ label[1] }}'
        {% endfor %}
    stressors:
      cpu:
        workers: 1
        load: 100
        options: ['-c 0']
    duration: '40s'
    scheduler:
      cron: '@every 600s'
  TEMPLATE
end

def chaos_template_container_kill
  <<-TEMPLATE
  apiVersion: chaos-mesh.org/v1alpha1
  kind: PodChaos
  metadata:
    name: container-kill
    namespace: default
  spec:
    action: container-kill
    mode: one
    containerName: '{{ helm_chart_container_name }}'
    selector:
      labelSelectors:
        {% for label in labels %}
        '{{ label[0]}}': '{{ label[1] }}'
        {% endfor %}
    scheduler:
      cron: '@every 600s'
  TEMPLATE
end

def chaos_template_pod_network_latency
  <<-TEMPLATE
  apiVersion: litmuschaos.io/v1alpha1
  kind: ChaosEngine
  metadata:
    name: {{ test_name }}
    namespace: default
  spec:
    jobCleanUpPolicy: 'delete'
    annotationCheck: 'true'
    engineState: 'active'
    appinfo:
      appns: 'default'
      applabel: '{{ deployment_label}}={{ deployment_label_value }}'
      appkind: 'deployment'
    chaosServiceAccount: {{ chaos_experiment_name }}-sa
    experiments:
      - name: {{ chaos_experiment_name }}
        spec:
          components:
            env:
              # If not provided it will take the first container of target pod
              - name: TARGET_CONTAINER
                value: ''
              - name: NETWORK_INTERFACE
                value: 'eth0'
              - name: NETWORK_LATENCY
                value: '60000'
              - name: TOTAL_CHAOS_DURATION
                value: '{{ total_chaos_duration }}'
              # provide the name of container runtime
              # it supports docker, containerd, crio
              # default to docker
              - name: CONTAINER_RUNTIME
                value: 'containerd'
              # provide the socket file path
              # applicable only for containerd and crio runtime
              - name: SOCKET_PATH
                value: '/run/containerd/containerd.sock'
  TEMPLATE
end

def chaos_template_pod_network_corruption
  <<-TEMPLATE
  apiVersion: litmuschaos.io/v1alpha1
  kind: ChaosEngine
  metadata:
    name: {{ test_name }}
    namespace: default
  spec:
    jobCleanUpPolicy: 'delete'
    annotationCheck: 'true'
    engineState: 'active'
    appinfo:
      appns: 'default'
      applabel: '{{ deployment_label}}={{ deployment_label_value }}'
      appkind: 'deployment'
    chaosServiceAccount: {{ chaos_experiment_name }}-sa
    experiments:
      - name: {{ chaos_experiment_name }}
        spec:
          components:
            env:
              # If not provided it will take the first container of target pod
              - name: TARGET_CONTAINER
                value: ''
              - name: NETWORK_INTERFACE
                value: 'eth0'
              - name: NETWORK_PACKET_CORRUPTION_PERCENTAGE
                value: '100' #in PERCENTAGE
              - name: TOTAL_CHAOS_DURATION
                value: '{{ total_chaos_duration }}'
              - name: CONTAINER_RUNTIME
                value: 'containerd'
              - name: SOCKET_PATH
                value: '/run/containerd/containerd.sock'
  TEMPLATE
end

def chaos_template_pod_network_duplication
  <<-TEMPLATE
  apiVersion: litmuschaos.io/v1alpha1
  kind: ChaosEngine
  metadata:
    name: {{ test_name }}
    namespace: default
  spec:
    jobCleanUpPolicy: 'delete'
    annotationCheck: 'true'
    engineState: 'active'
    appinfo:
      appns: 'default'
      applabel: '{{ deployment_label}}={{ deployment_label_value }}'
      appkind: 'deployment'
    chaosServiceAccount: {{ chaos_experiment_name }}-sa
    experiments:
      - name: {{ chaos_experiment_name }}
        spec:
          components:
            env:
              - name: TOTAL_CHAOS_DURATION
                value: '60' # in seconds

              - name: NETWORK_PACKET_DUPLICATION_PERCENTAGE
                value: '100'
    
              - name: CONTAINER_RUNTIME
                value: 'containerd'

              # provide the socket file path
              - name: SOCKET_PATH
                value: '/run/containerd/containerd.sock'
                
              ## percentage of total pods to target
              - name: PODS_AFFECTED_PERC
                value: ''

  TEMPLATE
end


def chaos_template_disk_fill
  <<-TEMPLATE
  apiVersion: litmuschaos.io/v1alpha1
  kind: ChaosEngine
  metadata:
    name: {{ test_name }}
    namespace: default
  spec:
    annotationCheck: 'true'
    engineState: 'active'
    auxiliaryAppInfo: ''
    appinfo:
      appns: 'default'
      applabel: '{{ deployment_label}}={{ deployment_label_value }}'
      appkind: 'deployment'
    chaosServiceAccount: {{ chaos_experiment_name }}-sa
    jobCleanUpPolicy: 'delete'
    experiments:
      - name: {{ chaos_experiment_name }}
        spec:
          components:
            env:
              # specify the fill percentage according to the disk pressure required
              - name: EPHEMERAL_STORAGE_MEBIBYTES
                value: '500'
                
              - name: TARGET_CONTAINER
                value: '' 
              - name: FILL_PERCENTAGE
                value: ''
              - name: CONTAINER_PATH
                value: '/var/lib/containerd/io.containerd.grpc.v1.cri/containers/'
                            
  TEMPLATE
end

def chaos_template_pod_delete
  <<-TEMPLATE
  apiVersion: litmuschaos.io/v1alpha1
  kind: ChaosEngine
  metadata:
    name: {{ test_name }}
    namespace: default
  spec:
    engineState: 'active'
    appinfo:
      appns: 'default'
      applabel: '{{ deployment_label}}={{ deployment_label_value }}'
      appkind: 'deployment'
    chaosServiceAccount: {{ chaos_experiment_name }}-sa
    jobCleanUpPolicy: 'delete'
    experiments:
      - name: {{ chaos_experiment_name }}
        spec:
          components:
            env:
              # specify the fill percentage according to the disk pressure required
              - name: TOTAL_CHAOS_DURATION
                value: '{{ total_chaos_duration }}'
                
              - name: CHAOS_INTERVAL
                value: '10'
                
              - name: TARGET_PODS
                value: '{{ target_pod_name }}'
              - name: FORCE
                value: 'false'
  TEMPLATE
end

def chaos_template_pod_memory_hog
  <<-TEMPLATE
  apiVersion: litmuschaos.io/v1alpha1
  kind: ChaosEngine
  metadata:
    name: {{ test_name }}
    namespace: default
  spec:
    appinfo:
      appns: 'default'
      applabel: '{{ deployment_label}}={{ deployment_label_value }}'
      appkind: 'deployment'
    # It can be delete/retain
    jobCleanUpPolicy: 'delete'   
    # It can be active/stop
    engineState: 'active'    
    chaosServiceAccount: {{ chaos_experiment_name }}-sa
    experiments:
      - name: {{ chaos_experiment_name }}
        spec:
          components:
            env:
              # Enter the amount of memory in megabytes to be consumed by the application pod
              - name: MEMORY_CONSUMPTION
                value: '500'
  
              - name: TOTAL_CHAOS_DURATION
                value: '{{ total_chaos_duration }}'
              - name: TARGET_PODS
                value: '{{ target_pod_name }}'             
              # provide the name of container runtime
              # it supports docker, containerd, crio
              # default to docker
              - name: CONTAINER_RUNTIME
                value: 'containerd'
              # provide the socket file path
              # applicable only for containerd and crio runtime
              - name: SOCKET_PATH
                value: '/run/containerd/containerd.sock'
                          
  TEMPLATE
end

def chaos_template_node_drain
  <<-TEMPLATE
  apiVersion: litmuschaos.io/v1alpha1
  kind: ChaosEngine
  metadata:
    name: {{ test_name }}
    namespace: default
  spec:
    appinfo:
      appns: 'default'
      applabel: '{{ deployment_label}}={{ deployment_label_value }}'
      appkind: 'deployment'
    # It can be delete/retain
    jobCleanUpPolicy: 'delete'   
    # It can be active/stop
    engineState: 'active'    
    chaosServiceAccount: {{ chaos_experiment_name }}-sa
    experiments:
      - name: {{ chaos_experiment_name }}
        spec:
          components:
            env:
              - name: TOTAL_CHAOS_DURATION
                value: '{{ total_chaos_duration }}'

              - name: TARGET_NODE
                value: '{{ app_nodeName }}'                

  TEMPLATE
end
