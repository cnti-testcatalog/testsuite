# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "json"
require "../utils/utils.cr"

rolling_version_change_test_names = ["rolling_update", "rolling_downgrade", "rolling_version_change"]

desc "Configuration should be managed in a declarative manner, using ConfigMaps, Operators, or other declarative interfaces."

task "configuration", [
    "ip_addresses",
    "nodeport_not_used",
    "hostport_not_used",
    "hardcoded_ip_addresses_in_k8s_runtime_configuration",
    "secrets_used",
    "immutable_configmap",
    "alpha_k8s_apis",
    "require_labels",
    "latest_tag",
    "default_namespace"
  ] do |_, args|
  stdout_score("configuration", "configuration")
end

desc "Check if the CNF is running containers with labels configured?"
task "require_labels" do |_, args|
  Log.for("verbose").info { "require-labels" }
  Kyverno.install
  CNFManager::Task.task_runner(args) do |args, config|
    emoji_passed = "🏷️✔️"
    emoji_failed = "🏷️❌"
    policy_path = Kyverno.best_practice_policy("require_labels/require_labels.yaml")
    failures = Kyverno::PolicyAudit.run(policy_path, EXCLUDE_NAMESPACES)

    if failures.size == 0
      resp = upsert_passed_task("require_labels", "✔️  PASSED: Pods have the app.kubernetes.io/name label #{emoji_passed}")
    else
      resp = upsert_failed_task("require_labels", "✖️  FAILED: Pods should have the app.kubernetes.io/name label. #{emoji_failed}")
      failures.each do |failure|
        failure.resources.each do |resource|
          puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
        end
      end
    end
  end
end

desc "Check if the CNF installs resources in the default namespace"
task "default_namespace" do |_, args|
  Log.for("verbose").info { "default_namespace" }
  Kyverno.install
  CNFManager::Task.task_runner(args) do |args, config|
    emoji_passed = "🏷️✔️"
    emoji_failed = "🏷️❌"
    policy_path = Kyverno.best_practice_policy("disallow_default_namespace/disallow_default_namespace.yaml")
    failures = Kyverno::PolicyAudit.run(policy_path, EXCLUDE_NAMESPACES)

    if failures.size == 0
      resp = upsert_passed_task("default_namespace", "✔️  PASSED: default namespace is not being used #{emoji_passed}")
    else
      resp = upsert_failed_task("default_namespace", "✖️  FAILED: Resources are created in the default namespace #{emoji_failed}")
      failures.each do |failure|
        failure.resources.each do |resource|
          puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
        end
      end
    end
  end
end

desc "Check if the CNF uses container images with the latest tag"
task "latest_tag" do |_, args|
  Log.for("verbose").info { "latest_tag" }
  Kyverno.install
  emoji_passed = "🏷️✔️"
  emoji_failed = "🏷️❌"
  policy_path = Kyverno.best_practice_policy("disallow_latest_tag/disallow_latest_tag.yaml")
  failures = Kyverno::PolicyAudit.run(policy_path, EXCLUDE_NAMESPACES)

  if failures.size == 0
    resp = upsert_passed_task("latest_tag", "✔️  PASSED: Container images are not using the latest tag #{emoji_passed}")
  else
    resp = upsert_failed_task("latest_tag", "✖️  FAILED: Container images are using the latest tag #{emoji_failed}")
    failures.each do |failure|
      failure.resources.each do |resource|
        puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
      end
    end
  end
end

desc "Does a search for IP addresses or subnets come back as negative?"
task "ip_addresses" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "ip_addresses" if check_verbose(args)
    LOGGING.info("ip_addresses args #{args.inspect}")
    cdir = FileUtils.pwd()
    response = String::Builder.new
    helm_directory = config.cnf_config[:helm_directory]
    helm_chart_path = config.cnf_config[:helm_chart_path]
    if File.directory?(helm_chart_path)
      # Switch to the helm chart directory
      Dir.cd(helm_chart_path)
      # Look for all ip addresses that are not comments
      LOGGING.info "current directory: #{ FileUtils.pwd()}"
      # should catch comments (# // or /*) and ignore 0.0.0.0
      # note: grep wants * escaped twice
      Process.run("grep -r -P '^(?!.+0\.0\.0\.0)(?![[:space:]]*0\.0\.0\.0)(?!#)(?![[:space:]]*#)(?!\/\/)(?![[:space:]]*\/\/)(?!\/\\*)(?![[:space:]]*\/\\*)(.+([0-9]{1,3}[\.]){3}[0-9]{1,3})'  --exclude=*.txt", shell: true) do |proc|
        while line = proc.output.gets
          response << line
          VERBOSE_LOGGING.info "#{line}" if check_verbose(args)
        end
      end
      Dir.cd(cdir)
      parsed_resp = response.to_s
      if parsed_resp.size > 0
        puts "HARD CODED IP ADDRESSES".colorize(:red)
        puts parsed_resp
        resp = upsert_failed_task("ip_addresses","✖️  FAILED: IP addresses found")
      else
        resp = upsert_passed_task("ip_addresses", "✔️  PASSED: No IP addresses found")
      end
      resp
    else
      # TODO If no helm chart directory, exit with 0 points
      # ADD SKIPPED tag for points.yml to allow for 0 points
      Dir.cd(cdir)
      resp = upsert_passed_task("ip_addresses", "✔️  PASSED: No IP addresses found")
    end
  end
end

desc "Do all cnf images have versioned tags?"
task "versioned_tag", ["install_opa"] do |_, args|
  # todo wait for opa
   # unless KubectlClient::Get.resource_wait_for_install("Daemonset", "falco") 
   #   LOGGING.info "Falco Failed to Start"
   #   upsert_skipped_task("non_root_user", "✖️  SKIPPED: Skipping non_root_user: Falco failed to install. Check Kernel Headers are installed on the Host Systems(K8s).")
   #   node_pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
   #   pods = KubectlClient::Get.pods_by_label(node_pods, "app", "falco")
   #   falco_pod_name = pods[0].dig("metadata", "name")
   #   LOGGING.info "Falco Pod Name: #{falco_pod_name}"
   #   resp = KubectlClient.logs(falco_pod_name)
   #   puts "Falco Logs: #{resp[:output]}"
   #   next
   # end
   #
   CNFManager::Task.task_runner(args) do |args,config|
     VERBOSE_LOGGING.info "versioned_tag" if check_verbose(args)
     LOGGING.debug "cnf_config: #{config}"
     fail_msgs = [] of String
     task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
       test_passed = true
       kind = resource["kind"].downcase
       case kind 
       when  "deployment","statefulset","pod","replicaset", "daemonset"
         resource_yaml = KubectlClient::Get.resource(resource[:kind], resource[:name])
         pods = KubectlClient::Get.pods_by_resource(resource_yaml)
         pods.map do |pod|
           pod_name = pod.dig("metadata", "name")
           if OPA.find_non_versioned_pod(pod_name)
             fail_msg = "resource: #{resource} and pod #{pod_name} use a non versioned image."
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
     emoji_versioned_tag="🏷️✔️"
     emoji_non_versioned_tag="🏷️❌"

     if task_response
       upsert_passed_task("versioned_tag", "✔️  PASSED: Image uses a versioned tag #{emoji_versioned_tag}")
     else
       upsert_failed_task("versioned_tag", "✖️  FAILED: Image does not use a versioned tag #{emoji_non_versioned_tag}")
     end
   end
end

desc "Does the CNF use NodePort"
task "nodeport_not_used" do |_, args|
  # TODO rename task_runner to multi_cnf_task_runner
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "nodeport_not_used" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"
    release_name = config.cnf_config[:release_name]
    service_name  = config.cnf_config[:service_name]
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config, check_containers:false, check_service: true) do |resource, container, initialized|
      LOGGING.info "nodeport_not_used resource: #{resource}"
      if resource["kind"].downcase == "service"
        LOGGING.info "resource kind: #{resource}"
        service = KubectlClient::Get.resource(resource[:kind], resource[:name])
        LOGGING.debug "service: #{service}"
        service_type = service.dig?("spec", "type")
        LOGGING.info "service_type: #{service_type}"
        VERBOSE_LOGGING.debug service_type if check_verbose(args)
        if service_type == "NodePort"
          #TODO make a service selector and display the related resources
          # that are tied to this service
          puts "resource service: #{resource} has a NodePort that is being used".colorize(:red)
          test_passed=false
        end
        test_passed
      end
    end
    if task_response
      upsert_passed_task("nodeport_not_used", "✔️  PASSED: NodePort is not used")
    else
      upsert_failed_task("nodeport_not_used", "✖️  FAILED: NodePort is being used")
    end
  end
end

desc "Does the CNF use HostPort"
task "hostport_not_used" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "hostport_not_used" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"
    release_name = config.cnf_config[:release_name]
    service_name  = config.cnf_config[:service_name]
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]

    task_response = CNFManager.workload_resource_test(args, config, check_containers:false, check_service: true) do |resource, container, initialized|
      LOGGING.info "hostport_not_used resource: #{resource}"
      test_passed=true
      LOGGING.info "resource kind: #{resource}"
      k8s_resource = KubectlClient::Get.resource(resource[:kind], resource[:name])
      LOGGING.debug "resource: #{k8s_resource}"

      # per examaple https://github.com/cncf/cnf-testsuite/issues/164#issuecomment-904890977
      containers = k8s_resource.dig?("spec", "template", "spec", "containers")
      LOGGING.debug "containers: #{containers}"

      containers && containers.as_a.each do |single_container|
        ports = single_container.dig?("ports")

        ports && ports.as_a.each do |single_port|
          LOGGING.debug "single_port: #{single_port}"
          
          hostport = single_port.dig?("hostPort")

          LOGGING.debug "DAS hostPort: #{hostport}"

          if hostport
            puts "resource service: #{resource} has a HostPort that is being used".colorize(:red)
            test_passed=false
          end

        end 
      end
      test_passed
    end
    if task_response
      upsert_passed_task("hostport_not_used", "✔️  PASSED: HostPort is not used")
    else
      upsert_failed_task("hostport_not_used", "✖️  FAILED: HostPort is being used")
    end
  end
end

desc "Does the CNF have hardcoded IPs in the K8s resource configuration"
task "hardcoded_ip_addresses_in_k8s_runtime_configuration" do |_, args|
  task_response = CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "Task Name: hardcoded_ip_addresses_in_k8s_runtime_configuration" if check_verbose(args)
    helm_chart = config.cnf_config[:helm_chart]
    helm_directory = config.cnf_config[:helm_directory]
    release_name = config.cnf_config[:release_name]
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    current_dir = FileUtils.pwd
    helm = BinarySingleton.helm
    VERBOSE_LOGGING.info "Helm Path: #{helm}" if check_verbose(args)

    KubectlClient::Create.command("namespace hardcoded-ip-test")
    unless helm_chart.empty?
      if args.named["offline"]?
        info = AirGap.tar_info_by_config_src(helm_chart)
        LOGGING.info  "hardcoded_ip_addresses_in_k8s_runtime_configuration airgapped mode info: #{info}"
        helm_chart = info[:tar_name]
      end
      helm_install = Helm.install("--namespace hardcoded-ip-test hardcoded-ip-test #{helm_chart} --dry-run --debug > #{destination_cnf_dir}/helm_chart.yml")
    else
      helm_install = Helm.install("--namespace hardcoded-ip-test hardcoded-ip-test #{destination_cnf_dir}/#{helm_directory} --dry-run --debug > #{destination_cnf_dir}/helm_chart.yml")
      VERBOSE_LOGGING.info "helm_directory: #{helm_directory}" if check_verbose(args)
    end

    ip_search = File.read_lines("#{destination_cnf_dir}/helm_chart.yml").take_while{|x| x.match(/NOTES:/) == nil}.reduce([] of String) do |acc, x|
      (x.match(/([0-9]{1,3}[\.]){3}[0-9]{1,3}/) &&
       x.match(/([0-9]{1,3}[\.]){3}[0-9]{1,3}/).try &.[0] != "0.0.0.0") ? acc << x : acc
    end

    VERBOSE_LOGGING.info "IPs: #{ip_search}" if check_verbose(args)

    if ip_search.empty?
      upsert_passed_task("hardcoded_ip_addresses_in_k8s_runtime_configuration", "✔️  PASSED: No hard-coded IP addresses found in the runtime K8s configuration")
    else
      upsert_failed_task("hardcoded_ip_addresses_in_k8s_runtime_configuration", "✖️  FAILED: Hard-coded IP addresses found in the runtime K8s configuration")
    end
  rescue
    upsert_skipped_task("hardcoded_ip_addresses_in_k8s_runtime_configuration", "✖️  SKIPPED: unknown exception")
  ensure
    KubectlClient::Delete.command("namespace hardcoded-ip-test --force --grace-period 0")
  end
end

desc "Does the CNF use K8s Secrets?"
task "secrets_used" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    LOGGING.debug "cnf_config: #{config}"
    VERBOSE_LOGGING.info "secrets_used" if check_verbose(args)
    # Parse the cnf-testsuite.yml
    resp = ""
    emoji_probe="🧫"
    task_response = CNFManager.workload_resource_test(args, config, check_containers=false) do |resource, containers, volumes, initialized|
      LOGGING.info "resource: #{resource}"
      LOGGING.info "volumes: #{volumes}"

      volume_test_passed = false
      container_secret_mounted = false
      # Check to see any volume secrets are actually used
      volumes.as_a.each do |secret_volume|
        if secret_volume["secret"]?
          LOGGING.info "secret_volume: #{secret_volume["name"]}"
          container_secret_mounted = false
          containers.as_a.each do |container|
            if container["volumeMounts"]?
                vmount = container["volumeMounts"].as_a
              LOGGING.info "vmount: #{vmount}"
              LOGGING.debug "container[env]: #{container["env"]}"
              if (vmount.find { |x| x["name"] == secret_volume["name"]? })
                LOGGING.debug secret_volume["name"]
                container_secret_mounted = true
                volume_test_passed = true
              end
            end
          end
          # If any secret volume exists, and it is not mounted by a
          # container, issue a warning
          unless container_secret_mounted
            puts "Warning: secret volume #{secret_volume["name"]} not mounted".colorize(:yellow)
          end
        end
      end

      #  if there are any containers that have a secretkeyref defined
      #  but do not have a corresponding k8s secret defined, this
      #  is an installation problem, and does not stop the test from passing

      secrets = KubectlClient::Get.secrets
      secrets["items"].as_a.each do |s|
        s_name = s["metadata"]["name"]
        s_type = s["type"]
        VERBOSE_LOGGING.info "secret name: #{s_name}, type: #{s_type}" if check_verbose(args)
      end
      secret_keyref_found_and_not_ignored = false
      containers.as_a.each do |container|
        c_name = container["name"]
        VERBOSE_LOGGING.info "container: #{c_name} envs #{container["env"]?}" if check_verbose(args)
        if container["env"]?
          container["env"].as_a.find do |env|
            VERBOSE_LOGGING.debug "checking container: #{c_name}" if check_verbose(args)
            secret_keyref_found_and_not_ignored = secrets["items"].as_a.find do |s|
              s_name = s["metadata"]["name"]
              if IGNORED_SECRET_TYPES.includes?(s["type"])
                VERBOSE_LOGGING.info "container: #{c_name} ignored secret: #{s_name}" if check_verbose(args)
                next
              end
              VERBOSE_LOGGING.debug "checking secret: #{s_name}" if check_verbose(args)
              found = (s_name == env.dig?("valueFrom", "secretKeyRef", "name"))
              if found
                VERBOSE_LOGGING.info "container: #{c_name} found secret reference: #{s_name}" if check_verbose(args)
              end
              found
            end
          end
        end
      end

      # Always pass if any workload resource in a cnf uses a (non-exempt) secret.
      # If the  workload resource does not use a (non-exempt) secret, always skip.

      test_passed = false
      if secret_keyref_found_and_not_ignored || volume_test_passed
        test_passed = true
      end

      unless test_passed
        puts "No Secret Volumes or Container secretKeyRefs found for resource: #{resource}".colorize(:yellow)
      end
      test_passed
    end
    if task_response
      resp = upsert_passed_task("secrets_used","✔️  PASSED: Secrets defined and used #{emoji_probe}")
    else
      resp = upsert_skipped_task("secrets_used","⏭  #{secrets_used_skipped_msg(emoji_probe)}")
    end
    resp
  end
end

# https://www.cloudytuts.com/tutorials/kubernetes/how-to-create-immutable-configmaps-and-secrets/
class ImmutableConfigMapTemplate
  # elapsed_time should be Int32 but it is being passed as string
  # So the old behaviour has been retained as is to prevent any breakages
  def initialize(@test_url : String)
  end

  ECR.def_to_s("src/templates/immutable_configmap.yml.ecr")
end

desc "Does the CNF use immutable configmaps?"
task "immutable_configmap" do |_, args|
  task_response = CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "immutable_configmap" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"

    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]

    # https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/

    # feature test to see if immutable_configmaps are enabled
    # https://github.com/cncf/cnf-testsuite/issues/508#issuecomment-758438413

    test_config_map_filename = "#{destination_cnf_dir}/config_maps/test_config_map.yml";

    template = ImmutableConfigMapTemplate.new("doesnt_matter").to_s
    Log.debug { "test immutable_configmap template: #{template}" }
    File.write(test_config_map_filename, template)
    KubectlClient::Apply.file(test_config_map_filename)

    # now we change then apply again

    template = ImmutableConfigMapTemplate.new("doesnt_matter_again").to_s
    Log.debug { "test immutable_configmap change template: #{template}" }
    File.write(test_config_map_filename, template)

    immutable_configmap_supported = true
    # if the reapply with a change succedes immmutable configmaps is NOT enabled
    # if KubectlClient::Apply.file(test_config_map_filename) == 0
    apply_result = KubectlClient::Apply.file(test_config_map_filename)
    if apply_result[:status].success?
      Log.info { "kubectl apply failed for: #{test_config_map_filename}" }
      k8s_ver = KubectlClient.server_version
      if version_less_than(k8s_ver, "1.19.0")
        resp = "✖️  SKIPPED: immmutable configmaps are not supported in this k8s cluster.".colorize(:yellow)
        upsert_skipped_task("immutable_configmap", resp)
        immutable_configmap_supported = false
      else
        resp = "✖️  FAILED: immmutable configmaps are not enabled in this k8s cluster.".colorize(:red)
        upsert_failed_task("immutable_configmap", resp)
      end
    end

    # cleanup test configmap
    KubectlClient::Delete.file(test_config_map_filename)

    resp = ""
    emoji_probe="⚖️"
    cnf_manager_workload_resource_task_response = CNFManager.workload_resource_test(args, config, check_containers=false, check_service=true) do |resource, containers, volumes, initialized|
      Log.info { "resource: #{resource}" }
      Log.info { "volumes: #{volumes}" }

      config_maps_json = KubectlClient::Get.configmaps

      volume_test_passed = false
      config_map_volume_exists = false
      config_map_volume_mounted = true
      all_volume_configmap_are_immutable = true
      # Check to see all volume config maps are actually used
      # https://kubernetes.io/docs/concepts/storage/volumes/#configmap
      volumes.as_a.each do |config_map_volume|
        if config_map_volume["configMap"]?
          config_map_volume_exists = true
          Log.info { "config_map_volume: #{config_map_volume["name"]}"}
          container_config_map_mounted = false
          containers.as_a.each do |container|
            if container["volumeMounts"]?
                vmount = container["volumeMounts"].as_a
              Log.info { "vmount: #{vmount}"}
              Log.info { "container[env]: #{container["env"]? && container["env"]}" }
              if (vmount.find { |x| x["name"] == config_map_volume["name"]? })
                Log.info { config_map_volume["name"] }
                container_config_map_mounted = true
              end
            end
          end
          # If any config_map volume exists, and it is not mounted by a
          # container, fail test
          if container_config_map_mounted == false
            config_map_volume_mounted = false
          end

          Log.info { "config_maps_json[items][0]: #{config_maps_json["items"][0]}" }
          Log.info { "config_map_volume[configMap] #{config_map_volume["configMap"]}" }

          this_volume_config_map = config_maps_json["items"].as_a.find {|x| x["metadata"]? && x["metadata"]["name"]? && x["metadata"]["name"] == config_map_volume["configMap"]["name"] }

          Log.info { "this_volume_config_map: #{this_volume_config_map}" }
          # https://crystal-lang.org/api/0.20.4/Hash.html#key%3F%28value%29-instance-method
          unless config_map_volume_mounted && this_volume_config_map && this_volume_config_map["immutable"]? && this_volume_config_map["immutable"] == true
            all_volume_configmap_are_immutable = false
          end
        end
      end

      if config_map_volume_exists && config_map_volume_mounted && all_volume_configmap_are_immutable
        volume_test_passed = true
      end

      all_env_configmap_are_immutable = true

      containers.as_a.each do |container|
        Log.info { "container config_maps #{container["env"]?}" }
        if container["env"]?
          container["env"].as_a.find do |c|
            # https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#define-container-environment-variables-with-data-from-multiple-configmaps
            this_env_mounted_config_map_name = c.dig?("valueFrom", "configMapKeyRef", "name")
            if this_env_mounted_config_map_name

              this_env_mounted_config_map_json = config_maps_json["items"].as_a.find{ |s| s["metadata"]["name"] == this_env_mounted_config_map_name }

              Log.info { "blarf this_env_mounted_config_map_json #{this_env_mounted_config_map_json}" }
              unless this_env_mounted_config_map_json && this_env_mounted_config_map_json["immutable"]? && this_env_mounted_config_map_json["immutable"] == true
                Log.info {" configmap immutable = false" }
                all_env_configmap_are_immutable = false
              end
            end
          end
        end
      end

      all_volume_configmap_are_immutable && all_env_configmap_are_immutable
    end

    if cnf_manager_workload_resource_task_response
      resp = "✔️  PASSED: All volume or container mounted configmaps immutable #{emoji_probe}".colorize(:green)
      upsert_passed_task("immutable_configmap", resp)
    elsif immutable_configmap_supported
      resp = "✖️  FAILED: Found mutable configmap(s) #{emoji_probe}".colorize(:red)
      upsert_failed_task("immutable_configmap", resp)
    else
      resp = "✖️  SKIPPED: Immutable configmap(s) not supported #{emoji_probe}".colorize(:yellow)
      upsert_skipped_task("immutable_configmap", resp)
    end
    resp
  end
end

desc "Check if CNF uses Kubernetes alpha APIs"
task "alpha_k8s_apis" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "alpha_k8s_apis" } if check_verbose(args)

    unless check_poc(args)
      Log.info { "Skipping alpha_k8s_apis: not in poc mode" }
      puts "SKIPPED: alpha_k8s_apis".colorize(:yellow)
      next
    end

    ensure_kubeconfig!
    kubeconfig_orig = ENV["KUBECONFIG"]
    emoji="⭕️🔍"

    # No offline support for this task for now
    if args.named["offline"]? && args.named["offline"]? != "false"
      upsert_skipped_task("alpha_k8s_apis","⏭️  SKIPPED: alpha_k8s_apis chaos test skipped #{emoji}")
      next
    end

    # Get kubernetes version of the current server.
    # This is used to setup kind with same k8s image version.
    k8s_server_version = KubectlClient.server_version

    # Online mode workflow below
    offline = false
    cluster_name = "apisnooptest"
    # Ensure any old cluster is deleted
    KindManager.new.delete_cluster(cluster_name)
    apisnoop = ApiSnoop.new(FileUtils.pwd)
    # FileUtils.cp("apisnoop-kind.yaml", "tools/apisnoop/kind/kind+apisnoop.yaml")
    cluster = apisnoop.setup_kind_cluster(cluster_name, k8s_server_version)
    Log.info { "apisnoop cluster kubeconfig: #{cluster.kubeconfig}" }
    ENV["KUBECONFIG"] = "#{cluster.kubeconfig}"

    cnf_setup_complete = CNFManager.cnf_to_new_cluster(config, cluster.kubeconfig, offline)

    # CNF setup failed on kind cluster. Inform in test output.
    unless cnf_setup_complete
      puts "CNF failed to install on apisnoop cluster".colorize(:red)
      upsert_failed_task("alpha_k8s_apis", "✖️  FAILED: Could not check CNF for usage of Kubernetes alpha APIs #{emoji}")
      next
    end

    # CNF setup was fine on kind cluster. Check for usage of alpha Kubernetes APIs.
    Log.info { "CNF setup complete on apisnoop cluster" }

    Log.info { "Query the apisnoop database" }
    k8s_major_minor_version = k8s_server_version.split(".")[0..1].join(".")
    pod_name = "pod/apisnoop-#{cluster_name}-control-plane"
    db_query = "select count(*) from testing.audit_event where endpoint in (select endpoint from open_api where level='alpha' and release ilike '#{k8s_major_minor_version}%')"
    exec_cmd = "#{pod_name} --container snoopdb --kubeconfig #{cluster.kubeconfig} -- psql -d apisnoop -c \"#{db_query}\""

    result = KubectlClient.exec(exec_cmd)
    api_count = result[:output].split("\n")[2].to_i

    if api_count == 0
      upsert_passed_task("alpha_k8s_apis", "✔️  PASSED: CNF does not use Kubernetes alpha APIs #{emoji}")
    else
      upsert_failed_task("alpha_k8s_apis", "✖️  FAILED: CNF uses Kubernetes alpha APIs #{emoji}")
    end
  ensure
    if cluster_name != nil
      KindManager.new.delete_cluster(cluster_name)
      ENV["KUBECONFIG"]="#{kubeconfig_orig}"
    end
  end
end


def secrets_used_skipped_msg(emoji)
<<-TEMPLATE
SKIPPED: Secrets not used #{emoji}

To address this issue please see the USAGE.md documentation

TEMPLATE
end
