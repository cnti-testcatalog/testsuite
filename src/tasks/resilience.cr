# coding: utf-8
require "sam"
require "colorize"
require "crinja"
require "./utils/utils.cr"

desc "The CNF conformance suite checks to see if the CNFs are resilient to failures."
task "resilience", ["chaos_network_loss", "chaos_cpu_hog", "chaos_container_kill" ] do |t, args|
  VERBOSE_LOGGING.info "resilience" if check_verbose(args)
  VERBOSE_LOGGING.debug "resilience args.raw: #{args.raw}" if check_verbose(args)
  VERBOSE_LOGGING.debug "resilience args.named: #{args.named}" if check_verbose(args)
  stdout_score("resilience")
end

desc "Install Chaos Mesh"
task "install_chaosmesh" do |_, args|
  VERBOSE_LOGGING.info "install_chaosmesh" if check_verbose(args)
  current_dir = FileUtils.pwd 
  helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
  crd_install = `kubectl create -f https://raw.githubusercontent.com/pingcap/chaos-mesh/v0.8.0/manifests/crd.yaml`
  VERBOSE_LOGGING.info "#{crd_install}" if check_verbose(args)
  unless Dir.exists?("#{current_dir}/#{TOOLS_DIR}/chaos_mesh")
    # TODO use a tagged version
    fetch_chaos_mesh = `git clone https://github.com/pingcap/chaos-mesh.git #{current_dir}/#{TOOLS_DIR}/chaos_mesh`
    checkout_tag = `cd #{current_dir}/#{TOOLS_DIR}/chaos_mesh && git checkout tags/v0.8.0 && cd -`
  end
  install_chaos_mesh = `#{helm} install chaos-mesh #{current_dir}/#{TOOLS_DIR}/chaos_mesh/helm/chaos-mesh --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock`
  wait_for_resource("#{current_dir}/spec/fixtures/chaos_network_loss.yml")
  wait_for_resource("#{current_dir}/spec/fixtures/chaos_cpu_hog.yml")
  wait_for_resource("#{current_dir}/spec/fixtures/chaos_container_kill.yml")
end

desc "Uninstall Chaos Mesh"
task "uninstall_chaosmesh" do |_, args|
  VERBOSE_LOGGING.info "uninstall_chaosmesh" if check_verbose(args)
  current_dir = FileUtils.pwd
  helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
  crd_delete = `kubectl delete -f https://raw.githubusercontent.com/pingcap/chaos-mesh/master/manifests/crd.yaml`
  FileUtils.rm_rf("#{current_dir}/#{TOOLS_DIR}/chaos_mesh")
  delete_chaos_mesh = `#{helm} delete chaos-mesh`
end


desc "Does the CNF crash when network loss occurs"
task "chaos_network_loss", ["install_chaosmesh", "retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "chaos_network_loss" if check_verbose(args)
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = cnf_destination_dir(ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    deployment_name = config.get("deployment_name").as_s
    deployment_label = config.get("deployment_label").as_s
    helm_chart_container_name = config.get("helm_chart_container_name").as_s
    LOGGING.debug "#{destination_cnf_dir}"
    LOGGING.info "destination_cnf_dir #{destination_cnf_dir}"
    deployment = Totem.from_file "#{destination_cnf_dir}/manifest.yml"
    emoji_chaos_network_loss="📶☠️"

    errors = 0
    begin
      deployment_label_value = deployment.get("metadata").as_h["labels"].as_h[deployment_label].as_s
    rescue ex
      errors = errors + 1
      LOGGING.error ex.message 
    end
    if errors < 1
      template = Crinja.render(network_chaos_template, { "deployment_label" => "#{deployment_label}", "deployment_label_value" => "#{deployment_label_value}" })
      chaos_config = `echo "#{template}" > "#{destination_cnf_dir}/chaos_network_loss.yml"`
      VERBOSE_LOGGING.debug "#{chaos_config}" if check_verbose(args)
      run_chaos = `kubectl create -f "#{destination_cnf_dir}/chaos_network_loss.yml"`
      VERBOSE_LOGGING.debug "#{run_chaos}" if check_verbose(args)
      # TODO fail if exceeds
      if wait_for_test("NetworkChaos", "network-loss")
        LOGGING.info( "Wait Done")
        if desired_is_available?(deployment_name)
          resp = upsert_passed_task("chaos_network_loss","✔️  PASSED: Replicas available match desired count after network chaos test #{emoji_chaos_network_loss}")
        else
          resp = upsert_failed_task("chaos_network_loss","✖️  FAILURE: Replicas did not return desired count after network chaos test #{emoji_chaos_network_loss}")
        end
      else
        # TODO Change this to an exception (points = 0)
        # e.g. upsert_exception_task
        resp = upsert_failed_task("chaos_network_loss","✖️  FAILURE: Chaosmesh failed to finish.")
      end
      delete_chaos = `kubectl delete -f "#{destination_cnf_dir}/chaos_network_loss.yml"`
    else
      resp = upsert_failed_task("chaos_network_loss","✖️  FAILURE: No deployment label found for network chaos test")
    end
  end
end

desc "Does the CNF crash when CPU usage is high"
task "chaos_cpu_hog", ["install_chaosmesh", "retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "chaos_cpu_hog" if check_verbose(args)
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = cnf_destination_dir(ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    deployment_name = config.get("deployment_name").as_s
    deployment_label = config.get("deployment_label").as_s
    helm_chart_container_name = config.get("helm_chart_container_name").as_s
    LOGGING.debug "#{destination_cnf_dir}"
    LOGGING.info "destination_cnf_dir #{destination_cnf_dir}"
    deployment = Totem.from_file "#{destination_cnf_dir}/manifest.yml"
    emoji_chaos_cpu_hog="📦💻🐷📈"

    errors = 0
    begin
      deployment_label_value = deployment.get("metadata").as_h["labels"].as_h[deployment_label].as_s
    rescue ex
      errors = errors + 1
      LOGGING.error ex.message 
    end
    if errors < 1
      template = Crinja.render(cpu_chaos_template, { "deployment_label" => "#{deployment_label}", "deployment_label_value" => "#{deployment_label_value}" })
      chaos_config = `echo "#{template}" > "#{destination_cnf_dir}/chaos_cpu_hog.yml"`
      VERBOSE_LOGGING.debug "#{chaos_config}" if check_verbose(args)
      run_chaos = `kubectl create -f "#{destination_cnf_dir}/chaos_cpu_hog.yml"`
      VERBOSE_LOGGING.debug "#{run_chaos}" if check_verbose(args)
      # TODO fail if exceeds
      if wait_for_test("StressChaos", "burn-cpu")
        if desired_is_available?(deployment_name)
          resp = upsert_passed_task("chaos_cpu_hog","✔️  PASSED: Application pod is healthy after high CPU consumption #{emoji_chaos_cpu_hog}")
        else
          resp = upsert_failed_task("chaos_cpu_hog","✖️  FAILURE: Application pod is not healthy after high CPU consumption #{emoji_chaos_cpu_hog}")
        end
      else
        # TODO Change this to an exception (points = 0)
        # e.g. upsert_exception_task
        resp = upsert_failed_task("chaos_cpu_hog","✖️  FAILURE: Chaosmesh failed to finish.")
      end
      delete_chaos = `kubectl delete -f "#{destination_cnf_dir}/chaos_cpu_hog.yml"`
    else
      resp = upsert_failed_task("chaos_cpu_hog","✖️  FAILURE: No deployment label found for cpu chaos test")
    end
  end
end

desc "Does the CNF recover when its container is killed"
task "chaos_container_kill", ["install_chaosmesh", "retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "chaos_container_kill" if check_verbose(args)
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = cnf_destination_dir(ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    deployment_name = config.get("deployment_name").as_s
    deployment_label = config.get("deployment_label").as_s
    helm_chart_container_name = config.get("helm_chart_container_name").as_s
    LOGGING.debug "#{destination_cnf_dir}"
    LOGGING.info "destination_cnf_dir #{destination_cnf_dir}"
    deployment = Totem.from_file "#{destination_cnf_dir}/manifest.yml"
    emoji_chaos_container_kill="🗡️💀♻️"

    errors = 0
    begin
      deployment_label_value = deployment.get("metadata").as_h["labels"].as_h[deployment_label].as_s
    rescue ex
      errors = errors + 1
      LOGGING.error ex.message 
    end
    if errors < 1
      template = Crinja.render(chaos_template_container_kill, { "deployment_label" => "#{deployment_label}", "deployment_label_value" => "#{deployment_label_value}", "helm_chart_container_name" => "#{helm_chart_container_name}" })
      chaos_config = `echo "#{template}" > "#{destination_cnf_dir}/chaos_container_kill.yml"`
      VERBOSE_LOGGING.debug "#{chaos_config}" if check_verbose(args)
      run_chaos = `kubectl create -f "#{destination_cnf_dir}/chaos_container_kill.yml"`
      VERBOSE_LOGGING.debug "#{run_chaos}" if check_verbose(args)
      # TODO fail if exceeds
      if wait_for_test("PodChaos", "container-kill")
        wait_for_install(deployment_name, wait_count=60)
        if desired_is_available?(deployment_name)
          resp = upsert_passed_task("chaos_container_kill","✔️  PASSED: Replicas available match desired count after container kill test #{emoji_chaos_container_kill}")
        else
          resp = upsert_failed_task("chaos_container_kill","✖️  FAILURE: Replicas did not return desired count after container kill test #{emoji_chaos_container_kill}")
        end
      else
        # TODO Change this to an exception (points = 0)
        # e.g. upsert_exception_task
        resp = upsert_failed_task("chaos_container_kill","✖️  FAILURE: Chaosmesh failed to finish.")
      end
      delete_chaos = `kubectl delete -f "#{destination_cnf_dir}/chaos_container_kill.yml"`
    else
      resp = upsert_failed_task("chaos_container_kill","✖️  FAILURE: No deployment label found for container kill test")
    end
  end
end

def wait_for_test(test_type, test_name)
  second_count = 0
  wait_count = 60
  status = ""
  until (status.empty? != true && status == "Finished") || second_count > wait_count.to_i
    LOGGING.debug "second_count = #{second_count}"
    sleep 1
    get_status = `kubectl get "#{test_type}" "#{test_name}" -o yaml`
    LOGGING.info("#{get_status}")
    status_data = Totem.from_yaml("#{get_status}")
    LOGGING.info "Status: #{get_status}"
    LOGGING.debug("#{status_data}")
    status = status_data.get("status").as_h["experiment"].as_h["phase"].as_s
    second_count = second_count + 1
    LOGGING.info "#{get_status}"
    LOGGING.info "#{second_count}"
  end
  # Did chaos mesh finish the test successfully
  (status.empty? !=true && status == "Finished")
end

def desired_is_available?(deployment_name)
  resp = `kubectl get deployments #{deployment_name} -o=yaml`
  describe = Totem.from_yaml(resp)
  LOGGING.info("desired_is_available describe: #{describe.inspect}")
  desired_replicas = describe.get("status").as_h["replicas"].as_i
  LOGGING.info("desired_is_available desired_replicas: #{desired_replicas}")
  ready_replicas = describe.get("status").as_h["readyReplicas"]?
  unless ready_replicas.nil?
    ready_replicas = ready_replicas.as_i
  else
    ready_replicas = 0
  end
  LOGGING.info("desired_is_available ready_replicas: #{ready_replicas}")

  desired_replicas == ready_replicas
end

def wait_for_resource(resource_file)
  second_count = 0
  wait_count = 60
  is_resource_created = nil
  until (is_resource_created.nil? != true && is_resource_created == true) || second_count > wait_count.to_i
    LOGGING.info "second_count = #{second_count}"
    sleep 3
    `kubectl create -f #{resource_file} 2>&1 >/dev/null`
    is_resource_created = $?.success?
    LOGGING.info "Waiting for CRD"
    LOGGING.info "Status: #{is_resource_created}"
    LOGGING.debug "resource file: #{resource_file}"
    second_count = second_count + 1
  end
  `kubectl delete -f #{resource_file}`
end

def network_chaos_template
  <<-TEMPLATE
  apiVersion: pingcap.com/v1alpha1
  kind: NetworkChaos
  metadata:
    name: network-loss
    namespace: default
  spec:
    action: loss
    mode: one
    selector:
      labelSelectors:
        '{{ deployment_label}}': '{{ deployment_label_value }}'
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
  apiVersion: pingcap.com/v1alpha1
  kind: StressChaos
  metadata:
    name: burn-cpu
    namespace: default
  spec:
    mode: one
    selector:
      labelSelectors:
        '{{ deployment_label}}': '{{ deployment_label_value }}'
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
  apiVersion: pingcap.com/v1alpha1
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
        '{{ deployment_label}}': '{{ deployment_label_value }}'
    scheduler:
      cron: '@every 600s'
  TEMPLATE
end
