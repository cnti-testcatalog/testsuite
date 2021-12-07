# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

def ensure_kubeconfig!
  puts "KUBECONFIG is not set. Please set a KUBECONFIG, i.p 'export KUBECONFIG=path-to-your-kubeconfig'".colorize(:red) unless ENV.has_key?("KUBECONFIG")
  raise "KUBECONFIG is not set. Please set a KUBECONFIG, i.p 'export KUBECONFIG=path-to-your-kubeconfig'" unless ENV.has_key?("KUBECONFIG")
end

desc "CNFs should work with any Certified Kubernetes product and any CNI-compatible network that meet their functionality requirements."
task "compatibility", ["cni_compatible"] do |_, args|
  stdout_score("compatibility")
end

def setup_calico_cluster(cluster_name : String, offline : Bool) : KindManager::Cluster
  if offline
    Log.info { "Running cni_compatible(Cluster Creation) in Offline Mode" }

    chart_directory = "#{TarClient::TAR_REPOSITORY_DIR}/projectcalico_tigera-operator"
    chart = Dir.entries("#{chart_directory}")[1]
    status = `docker image load -i #{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/kind-node.tar`
    Log.info { "#{status}" }
    Log.info { "Installing Airgapped CNI Chart: #{chart_directory}/#{chart}" }
    calico_cluster = KindManager.create_cluster_with_chart_and_wait(
      cluster_name,
      KindManager.disable_cni_config,
      "#{chart_directory}/#{chart} --namespace calico",
      offline
    )
    ENV["KUBECONFIG"]="#{calico_cluster.kubeconfig}"
    #TODO Don't bootstrap all images, only Calico & Cilium are needed.
    if Dir.exists?("#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}")
      AirGap.cache_images(kind_name: "calico-test-control-plane" )
      AirGap.cache_images(cnf_setup: true, kind_name: "calico-test-control-plane" )
    else
      puts "Bootstrap directory is missing, please run ./cnf-testsuite setup offline=<path-to-your-airgapped.tar.gz>".colorize(:red)
      raise "Bootstrap directory is missing, please run ./cnf-testsuite setup offline=<path-to-your-airgapped.tar.gz>"
    end
  else
    Log.info { "Running cni_compatible(Cluster Creation) in Online Mode" }
    Helm.helm_repo_add("projectcalico","https://docs.projectcalico.org/charts")
    calico_cluster = KindManager.create_cluster_with_chart_and_wait(
      cluster_name,
      KindManager.disable_cni_config,
      "projectcalico/tigera-operator --version v3.20.2",
      offline
    )
  end

  return calico_cluster
end

def setup_cilium_cluster(cluster_name : String, offline : Bool) : KindManager::Cluster
  chart_opts = [
    "--set operator.replicas=1",
    "--set image.repository=cilium/cilium",
    "--set image.useDigest=false",
    "--set operator.image.useDigest=false",
    "--set operator.image.repository=cilium/operator"
  ]

  kind_manager = KindManager.new
  cluster = kind_manager.create_cluster(cluster_name, KindManager.disable_cni_config, offline)

  if offline
    chart_directory = "#{TarClient::TAR_REPOSITORY_DIR}/cilium_cilium"
    chart = Dir.entries("#{chart_directory}")[2]
    Log.info { "Installing Airgapped CNI Chart: #{chart_directory}/#{chart}" }

    chart = "#{chart_directory}/#{chart}"
    Helm.install("#{cluster_name}-plugin #{chart} #{chart_opts.join(" ")} --namespace kube-system --kubeconfig #{cluster.kubeconfig}")

    ENV["KUBECONFIG"]="#{cluster.kubeconfig}"
    if Dir.exists?("#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}")
      AirGap.cache_images(kind_name: "cilium-test-control-plane" )
      AirGap.cache_images(cnf_setup: true, kind_name: "cilium-test-control-plane" )
    else
      puts "Bootstrap directory is missing, please run ./cnf-testsuite setup offline=<path-to-your-airgapped.tar.gz>".colorize(:red)
      raise "Bootstrap directory is missing, please run ./cnf-testsuite setup offline=<path-to-your-airgapped.tar.gz>"
    end
  else
    Helm.helm_repo_add("cilium","https://helm.cilium.io/")
    chart = "cilium/cilium"
    chart_opts.push("--version 1.10.5")
    Helm.install("#{cluster_name}-plugin #{chart} #{chart_opts.join(" ")} --namespace kube-system --kubeconfig #{cluster.kubeconfig}")
  end

  cluster.wait_until_pods_ready()
  Log.info { "cilium kubeconfig: #{cluster.kubeconfig}" }
  return cluster
end

desc "Check if CNF compatible with multiple CNIs"
task "cni_compatible" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.for("verbose").info { "cni_compatible" } if check_verbose(args)

    ensure_kubeconfig!
    kubeconfig_orig = ENV["KUBECONFIG"]

    if args.named["offline"]? && args.named["offline"]? != "false"
      offline = true
    else
      offline = false
    end

    calico_cluster = setup_calico_cluster("calico-test", offline)
    Log.info { "calico kubeconfig: #{calico_cluster.kubeconfig}" }
    calico_cnf_passed = CNFManager.cnf_to_new_cluster(config, calico_cluster.kubeconfig, offline)
    Log.info { "calico_cnf_passed: #{calico_cnf_passed}" }
    puts "CNF failed to install on Calico CNI cluster".colorize(:red) unless calico_cnf_passed

    cilium_cluster = setup_cilium_cluster("cilium-test", offline)
    cilium_cnf_passed = CNFManager.cnf_to_new_cluster(config, cilium_cluster.kubeconfig, offline)
    Log.info { "cilium_cnf_passed: #{cilium_cnf_passed}" }
    puts "CNF failed to install on Cilium CNI cluster".colorize(:red) unless cilium_cnf_passed

    emoji_security="🔓🔑"
    if calico_cnf_passed && cilium_cnf_passed
      upsert_passed_task("cni_compatible", "✔️  PASSED: CNF compatible with both Calico and Cilium #{emoji_security}")
    else
      upsert_failed_task("cni_compatible", "✖️  FAILED: CNF not compatible with either Calico or Cillium #{emoji_security}")
    end
  ensure
    kind_manager = KindManager.new
    kind_manager.delete_cluster("calico-test")
    kind_manager.delete_cluster("cilium-test")
    ENV["KUBECONFIG"]="#{kubeconfig_orig}"
  end
end
