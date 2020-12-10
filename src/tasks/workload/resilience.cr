# coding: utf-8
require "sam"
require "colorize"
require "crinja"
require "../utils/utils.cr"

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
    helm_directory = "#{config.get("helm_directory").as_s?}"
    manifest_directory = optional_key_as_string(config, "manifest_directory")
    release_name = "#{config.get("release_name").as_s?}"
    helm_chart_path = destination_cnf_dir + "/" + helm_directory
    manifest_file_path = destination_cnf_dir + "/" + "temp_template.yml"
    LOGGING.debug "#{destination_cnf_dir}"
    LOGGING.info "destination_cnf_dir #{destination_cnf_dir}"
    emoji_chaos_network_loss="📶☠️"

    if release_name.empty? # no helm chart
      template_ymls = Helm::Manifest.manifest_ymls_from_file_list(Helm::Manifest.manifest_file_list( destination_cnf_dir + "/" + manifest_directory))
    else
      Helm.generate_manifest_from_templates(release_name, 
                                          helm_chart_path, 
                                          manifest_file_path)
      template_ymls = Helm::Manifest.parse_manifest_as_ymls(manifest_file_path) 
    end

    deployment_ymls = Helm.workload_resource_by_kind(template_ymls, Helm::DEPLOYMENT)
    deployment_names = Helm.workload_resource_names(deployment_ymls)
    LOGGING.info "deployment names: #{deployment_names}"
    if deployment_names && deployment_names.size > 0 
      test_passed = true
    else
        puts "No deployment names found for container kill test".colorize(:red)
      test_passed = false
    end
    deployment_names.each do | deployment_name |

      if KubectlClient::Get.deployment_spec_labels(deployment_name).as_h? && KubectlClient::Get.deployment_spec_labels(deployment_name).as_h.size > 0
        test_passed = true
      else
        puts "No deployment label found for container kill test for deployment: #{deployment_name}".colorize(:red)
        test_passed = false
      end

      if test_passed
        template = Crinja.render(network_chaos_template, { "labels" => KubectlClient::Get.deployment_spec_labels(deployment_name).as_h })
        chaos_config = `echo "#{template}" > "#{destination_cnf_dir}/chaos_network_loss.yml"`
        VERBOSE_LOGGING.debug "#{chaos_config}" if check_verbose(args)
        run_chaos = `kubectl create -f "#{destination_cnf_dir}/chaos_network_loss.yml"`
        VERBOSE_LOGGING.debug "#{run_chaos}" if check_verbose(args)
        if wait_for_test("NetworkChaos", "network-loss")
          LOGGING.info( "Wait Done")
          unless desired_is_available?(deployment_name)
            test_passed = false
            puts "Replicas did not return desired count after network chaos test for deployment: #{deployment_name}".colorize(:red)
            # resp = upsert_failed_task("chaos_network_loss","✖️  FAILURE: Replicas did not return desired count after network chaos test #{emoji_chaos_network_loss}")
          end
        else
          # TODO Change this to an exception (points = 0)
          # e.g. upsert_exception_task
          test_passed = false
          puts "Chaosmesh failed to finish for deployment: #{deployment_name}".colorize(:red)
          # resp = upsert_failed_task("chaos_network_loss","✖️  FAILURE: Chaosmesh failed to finish.")
        end
      end
    end
    if test_passed
      resp = upsert_passed_task("chaos_network_loss","✔️  PASSED: Replicas available match desired count after network chaos test #{emoji_chaos_network_loss}")
    else
      resp = upsert_failed_task("chaos_network_loss","✖️  FAILURE: No deployment label found for network chaos test")
    end
  ensure
    delete_chaos = `kubectl delete -f "#{destination_cnf_dir}/chaos_network_loss.yml"`
  end
end

desc "Does the CNF crash when CPU usage is high"
task "chaos_cpu_hog", ["install_chaosmesh", "retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "chaos_cpu_hog" if check_verbose(args)
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    helm_directory = "#{config.get("helm_directory").as_s?}"
    manifest_directory = optional_key_as_string(config, "manifest_directory")
    release_name = "#{config.get("release_name").as_s?}"
    helm_chart_path = destination_cnf_dir + "/" + helm_directory
    manifest_file_path = destination_cnf_dir + "/" + "temp_template.yml"
    LOGGING.debug "#{destination_cnf_dir}"
    LOGGING.info "destination_cnf_dir #{destination_cnf_dir}"
    emoji_chaos_cpu_hog="📦💻🐷📈"

    if release_name.empty? # no helm chart
      template_ymls = Helm::Manifest.manifest_ymls_from_file_list(Helm::Manifest.manifest_file_list( destination_cnf_dir + "/" + manifest_directory))
    else
      Helm.generate_manifest_from_templates(release_name, 
                                          helm_chart_path, 
                                          manifest_file_path)
      template_ymls = Helm::Manifest.parse_manifest_as_ymls(manifest_file_path) 
    end

    deployment_ymls = Helm.workload_resource_by_kind(template_ymls, Helm::DEPLOYMENT)
    deployment_names = Helm.workload_resource_names(deployment_ymls)
    LOGGING.info "deployment names: #{deployment_names}"
    if deployment_names && deployment_names.size > 0 
      test_passed = true
    else
        puts "No deployment names found for container kill test".colorize(:red)
      test_passed = false
    end
    deployment_names.each do | deployment_name |
      if KubectlClient::Get.deployment_spec_labels(deployment_name).as_h? && KubectlClient::Get.deployment_spec_labels(deployment_name).as_h.size > 0
        test_passed = true
      else
        puts "No deployment label found for container kill test for deployment: #{deployment_name}".colorize(:red)
        test_passed = false
      end
      if test_passed
        template = Crinja.render(cpu_chaos_template, { "labels" => KubectlClient::Get.deployment_spec_labels(deployment_name).as_h })
        chaos_config = `echo "#{template}" > "#{destination_cnf_dir}/chaos_cpu_hog.yml"`
        VERBOSE_LOGGING.debug "#{chaos_config}" if check_verbose(args)
        run_chaos = `kubectl create -f "#{destination_cnf_dir}/chaos_cpu_hog.yml"`
        VERBOSE_LOGGING.debug "#{run_chaos}" if check_verbose(args)
        # TODO fail if exceeds
        if wait_for_test("StressChaos", "burn-cpu")
          unless desired_is_available?(deployment_name)
            test_passed = false
            puts "Chaosmesh Application pod is not healthy after high CPU consumption for deployment: #{deployment_name}".colorize(:red)
          end
        else
          # TODO Change this to an exception (points = 0)
          # e.g. upsert_exception_task
            test_passed = false
            puts "Chaosmesh failed to finish for deployment: #{deployment_name}".colorize(:red)
          # resp = upsert_failed_task("chaos_cpu_hog","✖️  FAILURE: Chaosmesh failed to finish.")
        end
      end
    end
    if test_passed
      resp = upsert_passed_task("chaos_cpu_hog","✔️  PASSED: Application pod is healthy after high CPU consumption #{emoji_chaos_cpu_hog}")
    else
      resp = upsert_failed_task("chaos_cpu_hog","✖️  FAILURE: Application pod is not healthy after high CPU consumption #{emoji_chaos_cpu_hog}")
    end
  ensure
    delete_chaos = `kubectl delete -f "#{destination_cnf_dir}/chaos_cpu_hog.yml"`
  end
end

desc "Does the CNF recover when its container is killed"
task "chaos_container_kill", ["install_chaosmesh", "retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "chaos_container_kill" if check_verbose(args)
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    helm_directory = "#{config.get("helm_directory").as_s?}"
    manifest_directory = optional_key_as_string(config, "manifest_directory")
    release_name = "#{config.get("release_name").as_s?}"
    helm_chart_path = destination_cnf_dir + "/" + helm_directory
    manifest_file_path = destination_cnf_dir + "/" + "temp_template.yml"
    LOGGING.debug "#{destination_cnf_dir}"
    LOGGING.info "destination_cnf_dir #{destination_cnf_dir}"
    emoji_chaos_container_kill="🗡️💀♻️"

    if release_name.empty? # no helm chart
      template_ymls = Helm::Manifest.manifest_ymls_from_file_list(Helm::Manifest.manifest_file_list( destination_cnf_dir + "/" + manifest_directory))
    else
      Helm.generate_manifest_from_templates(release_name, 
                                          helm_chart_path, 
                                          manifest_file_path)
      template_ymls = Helm::Manifest.parse_manifest_as_ymls(manifest_file_path) 
    end

    deployment_ymls = Helm.workload_resource_by_kind(template_ymls, Helm::DEPLOYMENT)
    deployment_names = Helm.workload_resource_names(deployment_ymls)
    LOGGING.info "deployment names: #{deployment_names}"
    if deployment_names && deployment_names.size > 0 
      test_passed = true
    else
        puts "No deployment names found for container kill test".colorize(:red)
      test_passed = false
    end
    deployment_names.each do | deployment_name |

      if KubectlClient::Get.deployment_spec_labels(deployment_name).as_h? && KubectlClient::Get.deployment_spec_labels(deployment_name).as_h.size > 0
        test_passed = true
      else
        puts "No deployment label found for container kill test for deployment: #{deployment_name}".colorize(:red)
        test_passed = false
      end
      if test_passed
        containers = KubectlClient::Get.deployment_containers(deployment_name)
        containers.as_a.each do |container|
          # TODO change helm_chart_container_name to container_name
          template = Crinja.render(chaos_template_container_kill, { "labels" => KubectlClient::Get.deployment_spec_labels(deployment_name).as_h, "helm_chart_container_name" => "#{container.as_h["name"]}" })
          LOGGING.debug "chaos template: #{template}"
          chaos_config = `echo "#{template}" > "#{destination_cnf_dir}/chaos_container_kill.yml"`
          VERBOSE_LOGGING.debug "#{chaos_config}" if check_verbose(args)
          run_chaos = `kubectl create -f "#{destination_cnf_dir}/chaos_container_kill.yml"`
          VERBOSE_LOGGING.debug "#{run_chaos}" if check_verbose(args)
          if wait_for_test("PodChaos", "container-kill")
            CNFManager.wait_for_install(deployment_name, wait_count=60)
          else
            # TODO Change this to an exception (points = 0)
            # e.g. upsert_exception_task
            test_passed = false
            puts "Chaosmesh chaos_container_kill failed to finish for deployment: #{deployment_name} and container: #{container.as_h["name"].as_s}".colorize(:red)
          end
        end
        # TODO fail if exceeds
        # if wait_for_test("PodChaos", "container-kill")
        # CNFManager.wait_for_install(deployment_name, wait_count=60)

      end
    end
    desired_passed = deployment_names.map do |x| 
     if desired_is_available?(x)
       true
     else
       puts "Replicas did not return desired count after container kill test for deployment: #{x}".colorize(:red)
       false
     end
    end
    if test_passed && desired_passed.all?
      resp = upsert_passed_task("chaos_container_kill","✔️  PASSED: Replicas available match desired count after container kill test #{emoji_chaos_container_kill}")
    else
      resp = upsert_failed_task("chaos_container_kill","✖️  FAILURE: Replicas did not return desired count after container kill test #{emoji_chaos_container_kill}")
    end
  ensure
    delete_chaos = `kubectl delete -f "#{destination_cnf_dir}/chaos_container_kill.yml"`
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
  apiVersion: pingcap.com/v1alpha1
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
        {% for label in labels %}
        '{{ label[0]}}': '{{ label[1] }}'
        {% endfor %}
    scheduler:
      cron: '@every 600s'
  TEMPLATE
end
