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

desc "Does the CNF crash when network loss occurs"
task "chaos_network_loss", ["install_chaosmesh", "retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "chaos_network_loss" if check_verbose(args)
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    deployment_name = config.get("deployment_name").as_s
    deployment_label = config.get("deployment_label").as_s
    # helm_chart_container_name = config.get("helm_chart_container_name").as_s
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
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    deployment_name = config.get("deployment_name").as_s
    deployment_label = config.get("deployment_label").as_s
    # helm_chart_container_name = config.get("helm_chart_container_name").as_s
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
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
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
      # TODO loop through all containers
      containers = KubectlClient::Get.deployment_containers(deployment_name)
      containers.as_a.each do |container|
        template = Crinja.render(chaos_template_container_kill, { "deployment_label" => "#{deployment_label}", "deployment_label_value" => "#{deployment_label_value}", "helm_chart_container_name" => "#{container.as_h["name"]}" })
        chaos_config = `echo "#{template}" > "#{destination_cnf_dir}/chaos_container_kill.yml"`
        VERBOSE_LOGGING.debug "#{chaos_config}" if check_verbose(args)
        run_chaos = `kubectl create -f "#{destination_cnf_dir}/chaos_container_kill.yml"`
        VERBOSE_LOGGING.debug "#{run_chaos}" if check_verbose(args)
        if wait_for_test("PodChaos", "container-kill")
          CNFManager.wait_for_install(deployment_name, wait_count=60)
        else
          # TODO Change this to an exception (points = 0)
          # e.g. upsert_exception_task
          resp = upsert_failed_task("chaos_container_kill","✖️  FAILURE: Chaosmesh failed to finish.")
        end
      end
      # TODO fail if exceeds
      # if wait_for_test("PodChaos", "container-kill")
      # CNFManager.wait_for_install(deployment_name, wait_count=60)
      if desired_is_available?(deployment_name)
        resp = upsert_passed_task("chaos_container_kill","✔️  PASSED: Replicas available match desired count after container kill test #{emoji_chaos_container_kill}")
      else
        resp = upsert_failed_task("chaos_container_kill","✖️  FAILURE: Replicas did not return desired count after container kill test #{emoji_chaos_container_kill}")
      end
      # else
      #   # TODO Change this to an exception (points = 0)
      #   # e.g. upsert_exception_task
      #   resp = upsert_failed_task("chaos_container_kill","✖️  FAILURE: Chaosmesh failed to finish.")
      # end
      delete_chaos = `kubectl delete -f "#{destination_cnf_dir}/chaos_container_kill.yml"`
    else
      resp = upsert_failed_task("chaos_container_kill","✖️  FAILURE: No deployment label found for container kill test")
    end
  end
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
