# coding: utf-8
require "sam"
require "colorize"
require "crinja"
require "./utils/utils.cr"

desc "The CNF conformance suite checks to see if the CNFs are resilient to failures."
task "resilience", ["chaos_network_loss"] do |t, args|
  puts "resilience args.raw: #{args.raw}" if check_verbose(args)
  puts "resilience args.named: #{args.named}" if check_verbose(args)
  total = total_points("resilience")
  if total > 0
    puts "Resilience final score: #{total} of #{total_max_points("resilience")}".colorize(:green)
  else
    puts "Resilience final score: #{total} of #{total_max_points("resilience")}".colorize(:red)
  end
end

desc "Install Chaos Mesh"
task "install_chaosmesh" do |_, args|
  current_dir = FileUtils.pwd 
  helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
  crd_install = `kubectl create -f https://raw.githubusercontent.com/pingcap/chaos-mesh/master/manifests/crd.yaml`
  puts "#{crd_install}" if check_verbose(args)
  unless Dir.exists?("#{current_dir}/#{TOOLS_DIR}/chaos_mesh")
    fetch_chaos_mesh = `git clone https://github.com/pingcap/chaos-mesh.git #{current_dir}/#{TOOLS_DIR}/chaos_mesh`
  end
  install_chaos_mesh = `#{helm} install chaos-mesh #{current_dir}/#{TOOLS_DIR}/chaos_mesh/helm/chaos-mesh --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock`
  wait_for_resource("#{current_dir}/spec/fixtures/chaos_network_loss.yml")
end

desc "Does the CNF crash when network loss occurs"
task "chaos_network_loss", ["install_chaosmesh", "retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args|
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = cnf_destination_dir(ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    deployment_name = config.get("deployment_name").as_s
    deployment_label = config.get("deployment_label").as_s
    helm_chart_container_name = config.get("helm_chart_container_name").as_s
    puts "#{destination_cnf_dir}"
    LOGGING.info "destination_cnf_dir #{destination_cnf_dir}"
    deployment = Totem.from_file "#{destination_cnf_dir}/manifest.yml"
    emoji_chaos_network_loss="📶☠️"

    errors = 0
    begin
      deployment_label_value = deployment.get("metadata").as_h["labels"].as_h[deployment_label].as_s
    rescue ex
      errors = errors + 1
      puts ex.message 
    end
    if errors < 1
      template = Crinja.render(chaos_template, { "deployment_label" => "#{deployment_label}", "deployment_label_value" => "#{deployment_label_value}" })
      chaos_config = `echo "#{template}" > "#{destination_cnf_dir}/chaos_network_loss.yml"`
      puts "#{chaos_config}" if check_verbose(args)
      run_chaos = `kubectl create -f "#{destination_cnf_dir}/chaos_network_loss.yml"`
      puts "#{run_chaos}" if check_verbose(args)
      # TODO fail if exceeds
      if wait_for_test("network-loss")
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
    delete_chaos_mesh
  end
end

def wait_for_test(test_name)
  second_count = 0
  wait_count = 60
  status = ""
  until (status.empty? != true && status == "Finished") || second_count > wait_count.to_i
    puts "second_count = #{second_count}"
    sleep 1
    get_status = `kubectl get NetworkChaos "#{test_name}" -o yaml`
    LOGGING.info("#{get_status}")
    status_data = Totem.from_yaml("#{get_status}")
    puts "Status: #{get_status}"
    puts "#{status_data}"
    status = status_data.get("status").as_h["experiment"].as_h["phase"].as_s
    second_count = second_count + 1
    puts "#{get_status}"
    puts "#{second_count}"
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
    puts "second_count = #{second_count}"
    sleep 3
    `kubectl create -f #{resource_file} 2>&1 >/dev/null`
    is_resource_created = $?.success?
    puts "Waiting for CRD"
    puts "Status: #{is_resource_created}"
    puts "#{resource_file}"
    second_count = second_count + 1
  end
  `kubectl delete -f #{resource_file}`
end

def chaos_template
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

def delete_chaos_mesh
  current_dir = FileUtils.pwd 
  helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
  crd_delete = `kubectl delete -f https://raw.githubusercontent.com/pingcap/chaos-mesh/master/manifests/crd.yaml`
  FileUtils.rm_rf("#{current_dir}/#{TOOLS_DIR}/chaos_mesh")
  delete_chaos_mesh = `#{helm} delete chaos-mesh`
end
