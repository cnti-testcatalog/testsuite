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
    "default_namespace",
    "operator_installed",
    "versioned_tag"
  ] do |_, args|
  stdout_score("configuration", "configuration")
  case "#{ARGV.join(" ")}" 
  when /configuration/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end

desc "Check if the CNF is running containers with labels configured?"
task "require_labels" do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    Kyverno.install
    policy_path = Kyverno.best_practice_policy("require_labels/require_labels.yaml")
    failures = Kyverno::PolicyAudit.run(policy_path, EXCLUDE_NAMESPACES)

    resource_keys = CNFManager.workload_resource_keys(args, config)
    failures = Kyverno.filter_failures_for_cnf_resources(resource_keys, failures)

    if failures.size == 0
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "Pods have the app.kubernetes.io/name label")
    else
      failures.each do |failure|
        failure.resources.each do |resource|
          puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
        end
      end
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Pods should have the app.kubernetes.io/name label.")
    end
  end
end

desc "Check if the CNF installs resources in the default namespace"
task "default_namespace" do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    Kyverno.install
    policy_path = Kyverno.best_practice_policy("disallow_default_namespace/disallow_default_namespace.yaml")
    failures = Kyverno::PolicyAudit.run(policy_path, EXCLUDE_NAMESPACES)

    resource_keys = CNFManager.workload_resource_keys(args, config)
    failures = Kyverno.filter_failures_for_cnf_resources(resource_keys, failures)

    if failures.size == 0
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "default namespace is not being used")
    else
      failures.each do |failure|
        failure.resources.each do |resource|
          puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
      end
      end
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Resources are created in the default namespace")
    end
  end
end

desc "Check if the CNF uses container images with the latest tag"
task "latest_tag" do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    Kyverno.install

    policy_path = Kyverno.best_practice_policy("disallow_latest_tag/disallow_latest_tag.yaml")
    failures = Kyverno::PolicyAudit.run(policy_path, EXCLUDE_NAMESPACES)

    resource_keys = CNFManager.workload_resource_keys(args, config)
    failures = Kyverno.filter_failures_for_cnf_resources(resource_keys, failures)

    if failures.size == 0
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "Container images are not using the latest tag")
    else
      failures.each do |failure|
        failure.resources.each do |resource|
          puts "#{resource.kind} #{resource.name} in #{resource.namespace} namespace failed. #{failure.message}".colorize(:red)
        end
      end
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Container images are using the latest tag")
    end
  end
end

desc "Does a search for IP addresses or subnets come back as negative?"
task "ip_addresses" do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    cdir = FileUtils.pwd()
    response = String::Builder.new
    helm_directory = config.cnf_config[:helm_directory]
    helm_chart_path = config.cnf_config[:helm_chart_path]
    Log.info { "Path: #{helm_chart_path}" }
    if File.directory?(helm_chart_path)
      # Switch to the helm chart directory
      Dir.cd(helm_chart_path)
      # Look for all ip addresses that are not comments
      Log.for(t.name).info { "current directory: #{ FileUtils.pwd()}" }
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
        response_lines = parsed_resp.split("\n")
        stdout_failure("Lines with hard-coded IP addresses:")
        response_lines.each do |line|
          line_parts = line.split(":")
          file_name = line_parts.shift()
          matching_line = line_parts.join(":").strip()
          stdout_failure("  * In file #{file_name}: #{matching_line}")
        end
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "IP addresses found")
      else
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "No IP addresses found")
      end
    else
      # TODO If no helm chart directory, exit with 0 points
      # ADD SKIPPED tag for points.yml to allow for 0 points
      Dir.cd(cdir)
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "No IP addresses found")
    end
  end
end

desc "Do all cnf images have versioned tags?"
task "versioned_tag", ["install_opa"] do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args,config|
    fail_msgs = [] of String
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
      kind = resource["kind"].downcase
      case kind
      when  "deployment","statefulset","pod","replicaset", "daemonset"
        resource_yaml = KubectlClient::Get.resource(resource[:kind], resource[:name], resource[:namespace])
        pods = KubectlClient::Get.pods_by_resource(resource_yaml, namespace: resource[:namespace])
        pods.map do |pod|
          pod_name = pod.dig("metadata", "name")
          if OPA.find_non_versioned_pod(pod_name)
            if kind == "pod"
              fail_msg = "Pod/#{resource[:name]} in #{resource[:namespace]} namespace does not use a versioned image"
            else
              fail_msg = "Pod/#{pod_name} in #{resource[:kind]}/#{resource[:name]} in #{resource[:namespace]} namespace does not use a versioned image"
            end
            unless fail_msgs.find{|x| x== fail_msg}
              fail_msgs << fail_msg
            end
            test_passed=false
          end
       end
      end
      test_passed
    end

    if task_response
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "Container images use versioned tags")
    else
      fail_msgs.each do |msg|
        stdout_failure(msg)
      end
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Container images do not use versioned tags")
    end
  end
end

desc "Does the CNF use NodePort"
task "nodeport_not_used" do |t, args|
  # TODO rename task_runner to multi_cnf_task_runner
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    release_name = config.cnf_config[:release_name]
    service_name  = config.cnf_config[:service_name]
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.workload_resource_test(args, config, check_containers: false, check_service: true) do |resource, container, initialized|
      Log.for(t.name).info { "nodeport_not_used resource: #{resource}" }
      if resource["kind"].downcase == "service"
        Log.for(t.name).info { "resource kind: #{resource}" }
        service = KubectlClient::Get.resource(resource[:kind], resource[:name], resource[:namespace])
        Log.for(t.name).debug { "service: #{service}" }
        service_type = service.dig?("spec", "type")
        Log.for(t.name).info { "service_type: #{service_type}" }
        if service_type == "NodePort"
          #TODO make a service selector and display the related resources
          # that are tied to this service
          stdout_failure("Resource #{resource[:kind]}/#{resource[:name]} in #{resource[:namespace]} namespace is using a NodePort")
          test_passed=false
        end
        test_passed
      end
    end
    if task_response
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "NodePort is not used")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "NodePort is being used")
    end
  end
end

desc "Does the CNF use HostPort"
task "hostport_not_used" do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    release_name = config.cnf_config[:release_name]
    service_name  = config.cnf_config[:service_name]
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]

    task_response = CNFManager.workload_resource_test(args, config, check_containers: false, check_service: true) do |resource, container, initialized|
      Log.for(t.name).info { "hostport_not_used resource: #{resource}" }
      test_passed=true
      Log.for(t.name).info { "resource kind: #{resource}" }
      k8s_resource = KubectlClient::Get.resource(resource[:kind], resource[:name], resource[:namespace])
      Log.for(t.name).debug { "resource: #{k8s_resource}" }

      # per examaple https://github.com/cnti-testcatalog/testsuite/issues/164#issuecomment-904890977
      containers = k8s_resource.dig?("spec", "template", "spec", "containers")
      Log.for(t.name).debug { "containers: #{containers}" }

      containers && containers.as_a.each do |single_container|
        ports = single_container.dig?("ports")

        ports && ports.as_a.each do |single_port|
          Log.for(t.name).debug { "single_port: #{single_port}" }
          
          hostport = single_port.dig?("hostPort")

          Log.for(t.name).debug { "DAS hostPort: #{hostport}" }

          if hostport
            stdout_failure("Resource #{resource[:kind]}/#{resource[:name]} in #{resource[:namespace]} namespace is using a HostPort")
            test_passed=false
          end

        end 
      end
      test_passed
    end
    if task_response
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "HostPort is not used")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "HostPort is being used")
    end
  end
end

desc "Does the CNF have hardcoded IPs in the K8s resource configuration"
task "hardcoded_ip_addresses_in_k8s_runtime_configuration" do |t, args|
  task_response = CNFManager::Task.task_runner(args, task: t) do |args, config|
    helm_chart = config.cnf_config[:helm_chart]
    helm_directory = config.cnf_config[:helm_directory]
    release_name = config.cnf_config[:release_name]
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    current_dir = FileUtils.pwd
    helm = Helm::BinarySingleton.helm
    VERBOSE_LOGGING.info "Helm Path: #{helm}" if check_verbose(args)

    KubectlClient::Create.command("namespace hardcoded-ip-test")
    unless helm_chart.empty?
      if args.named["offline"]?
        info = AirGap.tar_info_by_config_src(helm_chart)
        Log.for(t.name).info { "airgapped mode info: #{info}" }
        helm_chart = info[:tar_name]
      end
      helm_install = Helm.install("--namespace hardcoded-ip-test hardcoded-ip-test #{helm_chart} --dry-run --debug > #{destination_cnf_dir}/helm_chart.yml")
    else
      helm_install = Helm.install("--namespace hardcoded-ip-test hardcoded-ip-test #{destination_cnf_dir}/#{helm_directory} --dry-run --debug > #{destination_cnf_dir}/helm_chart.yml")
      VERBOSE_LOGGING.info "helm_directory: #{helm_directory}" if check_verbose(args)
    end

    ip_search = File.read_lines("#{destination_cnf_dir}/helm_chart.yml").take_while{|x| x.match(/NOTES:/) == nil}.reduce([] of String) do |acc, x|
      (x.match(/([0-9]{1,3}[\.]){3}[0-9]{1,3}/) &&
       x.match(/([0-9]{1,3}[\.]){3}[0-9]{1,3}/).try &.[0] != "0.0.0.0" &&
       x.match(/([0-9]{1,3}[\.]){3}[0-9]{1,3}/).try &.[0] != "127.0.0.1") ? acc << x : acc
    end

    VERBOSE_LOGGING.info "IPs: #{ip_search}" if check_verbose(args)

    if ip_search.empty?
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "No hard-coded IP addresses found in the runtime K8s configuration")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Hard-coded IP addresses found in the runtime K8s configuration")
    end
  rescue
    CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Skipped, "unknown exception")
  ensure
    KubectlClient::Delete.command("namespace hardcoded-ip-test --force --grace-period 0")
  end
end

desc "Does the CNF use K8s Secrets?"
task "secrets_used" do |t, args|
  CNFManager::Task.task_runner(args, task:t) do |args, config|
    # Parse the cnf-testsuite.yml
    resp = ""
    task_response = CNFManager.workload_resource_test(args, config, check_containers: false) do |resource, containers, volumes, initialized|
      Log.for(t.name).info { "resource: #{resource}" }
      Log.for(t.name).info { "volumes: #{volumes}" }

      volume_test_passed = false
      container_secret_mounted = false
      # Check to see any volume secrets are actually used
      volumes.as_a.each do |secret_volume|
        if secret_volume["secret"]?
          Log.for(t.name).info { "secret_volume: #{secret_volume["name"]}" }
          container_secret_mounted = false
          containers.as_a.each do |container|
            if container["volumeMounts"]?
                vmount = container["volumeMounts"].as_a
              Log.for(t.name).info { "vmount: #{vmount}" }
              Log.for(t.name).debug { "container[env]: #{container["env"]}" }
              if (vmount.find { |x| x["name"] == secret_volume["name"]? })
                Log.for(t.name).debug { secret_volume["name"] }
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

      namespace = resource[:namespace] || config.cnf_config[:helm_install_namespace]
      secrets = KubectlClient::Get.secrets(namespace: namespace)

      secrets["items"].as_a.each do |s|
        s_name = s["metadata"]["name"]
        s_type = s["type"]
        s_namespace = s.dig("metadata", "namespace")
        Log.for(t.name).info {"secret name: #{s_name}, type: #{s_type}, namespace: #{s_namespace}"} if check_verbose(args)
      end
      secret_keyref_found_and_not_ignored = false
      containers.as_a.each do |container|
        c_name = container["name"]
        Log.for(t.name).info { "container: #{c_name} envs #{container["env"]?}" } if check_verbose(args)
        if container["env"]?
          Log.for("container_info").info { container["env"] }
          container["env"].as_a.find do |env|
            Log.for(t.name).debug { "checking container: #{c_name}" } if check_verbose(args)
            secret_keyref_found_and_not_ignored = secrets["items"].as_a.find do |s|
              s_name = s["metadata"]["name"]
              if IGNORED_SECRET_TYPES.includes?(s["type"])
                Log.for("verbose").info { "container: #{c_name} ignored secret: #{s_name}" } if check_verbose(args)
                next
              end
              Log.for(t.name).info { "Checking secret: #{s_name}" }
              found = (s_name == env.dig?("valueFrom", "secretKeyRef", "name"))
              if found
                Log.for(t.name).info { "secret_reference_found. container: #{c_name} found secret reference: #{s_name}" }
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
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "Secrets defined and used")
    else
      puts "Secrets not used. To address this issue please see the USAGE.md documentation".colorize(:yellow)
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Skipped, "Secrets not used")
    end
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

alias MutableConfigMapsInEnvResult = NamedTuple(
  resource: NamedTuple(kind: String, name: String, namespace: String),
  container: String,
  configmap: String
)

alias MutableConfigMapsVolumesResult = NamedTuple(
  resource: NamedTuple(kind: String, name: String, namespace: String),
  container: String?,
  volume: String,
  configmap: String
)

def configmap_volume_mounted?(configmap_volume, container)
  return false if !container["volumeMounts"]?

  volume_mounts = container["volumeMounts"].as_a
  Log.for("container_volume_mounts").info { volume_mounts }
  result = volume_mounts.find { |x| x["name"] == configmap_volume["name"]? }
  return true if result
  false
end

def mutable_configmaps_as_volumes(
  resource : NamedTuple(kind: String, name: String, namespace: String),
  configmaps : Array(JSON::Any),
  volumes : Array(JSON::Any),
  containers : Array(JSON::Any)
) : Array(MutableConfigMapsVolumesResult)
  Log.for("immutable_configmap").info { "Resource: #{resource}; Volume count: #{volumes.size}" }

  # Select all configmap volumes
  configmap_volumes = volumes.select do |volume|
    volume["configMap"]?
  end

  Log.for("immutable_configmap").info { "Volume count for configmaps: #{volumes.size}" }
  Log.for("immutable_configmap").info { "Will loop through configmap volumes" }
  configmap_volumes.flat_map do |volume|
    Log.for("immutable_configmap:volume_item").info {volume}
    # Find the configmap that the volume is using
    configmap = configmaps.find{ |cm| cm["metadata"]["name"] == volume["configMap"]["name"]}
    Log.for("immutable_configmap:configmap_item").info {configmap}
    # Move on if the volume does not point to a valid configmap
    if !configmap
      next nil
    end

    containers.map do |container|
      # If configmap is immutable, then move on.
      if configmap["immutable"]? && configmap["immutable"] == true
        next nil
      end

      # If (configmap does not have immutable key OR configmap has immutable=false)
      if (!configmap["immutable"]? || (configmap["immutable"]? && configmap["immutable"] == false))
        Log.for("immutable_configmap_fail_volume").info { configmap }
        if configmap_volume_mounted?(volume, container)
          {resource: resource, container: container.dig("name").as_s, volume: volume["name"].as_s, configmap: configmap["metadata"]["name"].as_s}
        else
          {resource: resource, container: nil, volume: volume["name"].as_s, configmap: configmap["metadata"]["name"].as_s}
        end
      end
    end.compact
  end.compact
end

def container_env_configmap_refs(
  resource : NamedTuple(kind: String, name: String, namespace: String),
  configmaps : Array(JSON::Any),
  container : JSON::Any
) : Nil | Array(MutableConfigMapsInEnvResult)
  return nil if !container["env"]?

  Log.info { "container config_maps #{container["env"]?}" }
  container["env"].as_a.map do |item|
    # https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#define-container-environment-variables-with-data-from-multiple-configmaps
    env_configmap_ref = item.dig?("valueFrom", "configMapKeyRef", "name")
    next nil if env_configmap_ref == nil
    configmap = configmaps.find { |s| s["metadata"]["name"] == env_configmap_ref }
    next nil if configmap == nil

    if configmap && (!configmap["immutable"]? || (configmap["immutable"]? && configmap["immutable"] == false))
      Log.for("immutable_configmap_fail_env").info { configmap }
      {resource: resource, container: container.dig("name").as_s, configmap: configmap["metadata"]["name"].as_s}
    end
  end.compact
end

desc "Does the CNF use immutable configmaps?"
task "immutable_configmap" do |t, args|
  resp = ""

  task_response = CNFManager::Task.task_runner(args, task: t) do |args, config|
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]

    # https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/

    # feature test to see if immutable_configmaps are enabled
    # https://github.com/cnti-testcatalog/testsuite/issues/508#issuecomment-758438413

    test_config_map_filename = "#{destination_cnf_dir}/config_maps/test_config_map.yml";

    template = ImmutableConfigMapTemplate.new("doesnt_matter").to_s
    Log.for(t.name).debug { "test immutable_configmap template: #{template}" }
    File.write(test_config_map_filename, template)
    KubectlClient::Apply.file(test_config_map_filename)

    # now we change then apply again

    template = ImmutableConfigMapTemplate.new("doesnt_matter_again").to_s
    Log.for(t.name).debug { "test immutable_configmap change template: #{template}" }
    File.write(test_config_map_filename, template)

    immutable_configmap_supported = true
    immutable_configmap_enabled = true

    # if the reapply with a change succedes immmutable configmaps is NOT enabled
    # if KubectlClient::Apply.file(test_config_map_filename) == 0
    apply_result = KubectlClient::Apply.file(test_config_map_filename)

    # Delete configmap immediately to avoid interfering with further tests
    KubectlClient::Delete.file(test_config_map_filename)

    if apply_result[:status].success?
      Log.for(t.name).info { "kubectl apply on immutable configmap succeeded for: #{test_config_map_filename}" }
      k8s_ver = KubectlClient.server_version
      if version_less_than(k8s_ver, "1.19.0")
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Skipped, "immmutable configmaps are not supported in this k8s cluster")
      else
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "immmutable configmaps are not enabled in this k8s cluster")
      end
    else

      volumes_test_results = [] of MutableConfigMapsVolumesResult
      envs_with_mutable_configmap = [] of MutableConfigMapsInEnvResult

      cnf_manager_workload_resource_task_response = CNFManager.workload_resource_test(args, config, check_containers: false, check_service: true) do |resource, containers, volumes, initialized|
        Log.for(t.name).info { "resource: #{resource}" }
        Log.for(t.name).info { "volumes: #{volumes}" }

        # If the install type is manifest, the namesapce would be in the manifest.
        # Else rely on config for helm-based install
        namespace = resource[:namespace] || config.cnf_config[:helm_install_namespace]
        configmaps = KubectlClient::Get.configmaps(namespace: namespace)
        if configmaps.dig?("items")
          configmaps = configmaps.dig("items").as_a
        else
          configmaps = [] of JSON::Any
        end

        volumes_test_results = mutable_configmaps_as_volumes(resource, configmaps, volumes.as_a, containers.as_a)
        envs_with_mutable_configmap = containers.as_a.flat_map do |container|
          container_env_configmap_refs(resource, configmaps, container)
        end.compact

        Log.for("immutable_configmap_volumes").info { volumes_test_results }
        Log.for("immutable_configmap_envs").info { envs_with_mutable_configmap }

        volumes_test_results.size == 0 && envs_with_mutable_configmap.size == 0
      end

      if cnf_manager_workload_resource_task_response
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "All volume or container mounted configmaps immutable")
      elsif immutable_configmap_supported

        # Print out any mutable configmaps mounted as volumes
        volumes_test_results.each do |result|
          msg = ""
          if result[:resource] == nil
            msg = "Mutable configmap #{result[:configmap]} used as volume in #{result[:resource][:kind]}/#{result[:resource][:name]} in #{result[:resource][:namespace]} namespace."
          else
            msg = "Mutable configmap #{result[:configmap]} mounted as volume #{result[:volume]} in #{result[:container]} container part of #{result[:resource][:kind]}/#{result[:resource][:name]} in #{result[:resource][:namespace]} namespace."
          end
          stdout_failure(msg)
        end
        envs_with_mutable_configmap.each do |result|
          msg = "Mutable configmap #{result[:configmap]} used in env in #{result[:container]} part of #{result[:resource][:kind]}/#{result[:resource][:name]} in #{result[:resource][:namespace]}."
          stdout_failure(msg)
        end
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Found mutable configmap(s)")
      end
    end
  end
end

desc "Check if CNF uses Kubernetes alpha APIs"
task "alpha_k8s_apis" do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    unless check_poc(args)
      next CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Skipped, "alpha_k8s_apis not in poc mode")
    end

    ensure_kubeconfig!
    kubeconfig_orig = ENV["KUBECONFIG"]

    # No offline support for this task for now
    if args.named["offline"]? && args.named["offline"]? != "false"
      next CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Skipped, "alpha_k8s_apis chaos test skipped")
    end

    # Get kubernetes version of the current server.
    # This is used to setup kind with same k8s image version.
    k8s_server_version = KubectlClient.server_version

    # Online mode workflow below
    offline = false
    cluster_name = "apisnooptest"
    # Ensure any old cluster is deleted
    KindManager.new.delete_cluster(cluster_name)
    apisnoop = ApiSnoop.new()
    # FileUtils.cp("apisnoop-kind.yaml", "tools/apisnoop/kind/kind+apisnoop.yaml")
    cluster = apisnoop.setup_kind_cluster(cluster_name, k8s_server_version)
    Log.info { "apisnoop cluster kubeconfig: #{cluster.kubeconfig}" }
    ENV["KUBECONFIG"] = "#{cluster.kubeconfig}"

    cnf_setup_complete = CNFManager.cnf_to_new_cluster(config, cluster.kubeconfig, offline)

    # CNF setup failed on kind cluster. Inform in test output.
    unless cnf_setup_complete
      puts "CNF failed to install on apisnoop cluster".colorize(:red)
      next CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Could not check CNF for usage of Kubernetes alpha APIs")
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
      result = CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "CNF does not use Kubernetes alpha APIs")
    else
      result = CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "CNF uses Kubernetes alpha APIs")
    end
  ensure
    if cluster_name != nil
      KindManager.new.delete_cluster(cluster_name)
      ENV["KUBECONFIG"]="#{kubeconfig_orig}"
    end
    result
  end
end

desc "Does the CNF install an Operator with OLM?"
task "operator_installed" do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args,config|
    subscription_names = CNFManager.cnf_resources(args, config) do |resource|
      kind = resource.dig("kind").as_s
      if kind && kind.downcase == "subscription"
        { "name" => resource.dig("metadata", "name"), "namespace" => resource.dig("metadata", "namespace") }
      end
    end.compact

    Log.for(t.name).info { "Subscription Names: #{subscription_names}" }


    #TODO Warn if csv is not found for a subscription.
    csv_names = subscription_names.map do |subscription|
      second_count = 0
      wait_count = 120
      csv_created = nil
      resource_created = false

      KubectlClient::Get.wait_for_resource_key_value("sub", "#{subscription["name"]}", {"status", "installedCSV"}, namespace: subscription["namespace"].as_s)

      installed_csv = KubectlClient::Get.resource("sub", "#{subscription["name"]}", "#{subscription["namespace"]}")
      if installed_csv.dig?("status", "installedCSV")
        { "name" => installed_csv.dig("status", "installedCSV"), "namespace" => installed_csv.dig("metadata", "namespace") }
      end
    end.compact

    Log.for(t.name).info { "CSV Names: #{csv_names}" }


    succeeded = csv_names.map do |csv| 
      if KubectlClient::Get.wait_for_resource_key_value("csv", "#{csv["name"]}", {"status", "reason"}, namespace: csv["namespace"].as_s, value: "InstallSucceeded" ) && KubectlClient::Get.wait_for_resource_key_value("csv", "#{csv["name"]}", {"status", "phase"}, namespace: csv["namespace"].as_s, value: "Succeeded" )
        csv_succeeded=true
      end
      csv_succeeded
    end

    Log.for(t.name).info { "Succeeded CSV Names: #{succeeded}" }

    if succeeded.size > 0 && succeeded.all?(true)
      Log.for(t.name).info { "Succeeded All True?" }
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "Operator is installed: 🐜")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::NA, "No Operators Found 🦖")
    end
  end
end
