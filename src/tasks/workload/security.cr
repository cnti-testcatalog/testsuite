# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "CNF containers should be isolated from one another and the host.  The CNF Test suite uses tools like Falco, Sysdig Inspect and gVisor"
task "security", ["privileged"] do |_, args|
  stdout_score("security")
end

desc "Check if any containers are running in as root"
task "non_root_user", ["install_falco"] do |_, args|
   unless KubectlClient::Get.resource_wait_for_install("Daemonset", "falco") 
     LOGGING.info "Falco Failed to Start"
     upsert_skipped_task("non_root_user", "✖️  SKIPPED: Skipping non_root_user: Falco failed to install. Check Kernel Headers are installed on the Host Systems(K8s).")
     node_pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
     pods = KubectlClient::Get.pods_by_label(node_pods, "app", "falco")
     falco_pod_name = pods[0].dig("metadata", "name")
     LOGGING.info "Falco Pod Name: #{falco_pod_name}"
     KubectlClient.logs(falco_pod_name)
     next
   end

   CNFManager::Task.task_runner(args) do |args,config|
     VERBOSE_LOGGING.info "non_root_user" if check_verbose(args)
     LOGGING.debug "cnf_config: #{config}"
     fail_msgs = [] of String
     task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
       test_passed = true
       LOGGING.info "Falco is Running"
       kind = resource["kind"].as_s.downcase
       case kind 
       when  "deployment","statefulset","pod","replicaset", "daemonset"
         resource_yaml = KubectlClient::Get.resource(resource[:kind], resource[:name])
         pods = KubectlClient::Get.pods_by_resource(resource_yaml)
         # containers = KubectlClient::Get.resource_containers(kind, resource[:name]) 
         pods.map do |pod|
           # containers.as_a.map do |container|
           #   container_name = container.dig("name")
           pod_name = pod.dig("metadata", "name")
           # if Falco.find_root_pod(pod_name, container_name)
           if Falco.find_root_pod(pod_name)
             fail_msg = "resource: #{resource} and pod #{pod_name} uses a root user"
             unless fail_msgs.find{|x| x== fail_msg}
               puts fail_msg.colorize(:red)
               fail_msgs << fail_msg
             end
             test_passed=false
           end
         end
       end
       test_passed
     end
     emoji_no_root="🚫√"
     emoji_root="√"

     if task_response
       upsert_passed_task("non_root_user", "✔️  PASSED: Root user not found #{emoji_no_root}")
     else
       upsert_failed_task("non_root_user", "✖️  FAILED: Root user found #{emoji_root}")
     end
   end
end

desc "Check if any containers are running in privileged mode"
task "privileged" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "privileged" if check_verbose(args)
    white_list_container_names = config.cnf_config[:white_list_container_names]
    VERBOSE_LOGGING.info "white_list_container_names #{white_list_container_names.inspect}" if check_verbose(args)
    violation_list = [] of String
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|

      privileged_list = KubectlClient::Get.privileged_containers
      white_list_containers = ((PRIVILEGED_WHITELIST_CONTAINERS + white_list_container_names) - [container])
      # Only check the containers that are in the deployed helm chart or manifest
      (privileged_list & ([container.as_h["name"].as_s] - white_list_containers)).each do |x|
        violation_list << x
      end
      if violation_list.size > 0
        false
      else
        true
      end
    end
    LOGGING.debug "violator list: #{violation_list.flatten}"
    emoji_security="🔓🔑"
    if task_response 
      upsert_passed_task("privileged", "✔️  PASSED: No privileged containers #{emoji_security}")
    else
      upsert_failed_task("privileged", "✖️  FAILED: Found #{violation_list.size} privileged containers: #{violation_list.inspect} #{emoji_security}")
    end
  end
end
