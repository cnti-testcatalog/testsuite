require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

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
