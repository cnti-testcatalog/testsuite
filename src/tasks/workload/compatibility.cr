# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "CNFs should work with any Certified Kubernetes product and any CNI-compatible network that meet their functionality requirements."
task "compatibility", ["cni_compatible"] do |_, args|
end

desc "Check if CNF compatible with multiple CNIs"
task "cni_compatible" do |_, args|
  # if args.named["offline"]? || args.raw.includes? "offline"
  #     puts "offline mode cni_compatible skipped".colorize(:yellow) 
  # else
    CNFManager::Task.task_runner(args) do |args, config|
      VERBOSE_LOGGING.info "cni_compatible" if check_verbose(args)

      kubeconfig_orig = ENV["KUBECONFIG"]

      if args.named["offline"]?
            Log.info { "Running cni_compatible(Cluster Creation) in Offline Mode" }
            status = `docker image load -i #{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/kind-node.tar`
            Log.info { "#{status}" }
           kubeconfig = KindManager.create_cluster("calico-test", "#{TarClient::TAR_DOWNLOAD_DIR}/projectcalico_tigera-operator", offline=true)
           ENV["KUBECONFIG"]="#{kubeconfig}"
           #TODO Don't bootstrap all images, only Calico & Cilium are needed.
           if Dir.exists?("#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}")
             AirGap.cache_images()
           else
             puts "Bootstrap directory is missing, please run ./cnf-testsuite setup offline=<path-to-your-airgapped.tar.gz>".colorize(:red)
             raise "Bootstrap directory is missing, please run ./cnf-testsuite setup offline=<path-to-your-airgapped.tar.gz>"
           end
         else
           Log.info { "Running cni_compatible(Cluster Creation) in Online Mode" }
           Helm.helm_repo_add("projectcalico","https://docs.projectcalico.org/charts")
           kubeconfig = KindManager.create_cluster("calico-test", "projectcalico/tigera-operator --version v3.20.2", offline=false)
      end
      Log.info { "kubeconfig: #{kubeconfig}" }
      calico_cnf_passed = CNFManager.cnf_to_new_cluster(config, kubeconfig)
      Log.info { "calico_cnf_passed: #{calico_cnf_passed}" }
      puts "CNF failed to install on Calico CNI cluster".colorize(:red) unless calico_cnf_passed


      if args.named["offline"]?
           kubeconfig = KindManager.create_cluster("cilium-test", "#{TarClient::TAR_REPOSITORY_DIR}/cilium_cilium --set operator.replicas=1", offline=true)
           ENV["KUBECONFIG"]="#{kubeconfig}"
           if Dir.exists?("#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}")
             AirGap.cache_images()
           else
             puts "Bootstrap directory is missing, please run ./cnf-testsuite setup offline=<path-to-your-airgapped.tar.gz>".colorize(:red)
             raise "Bootstrap directory is missing, please run ./cnf-testsuite setup offline=<path-to-your-airgapped.tar.gz>"
           end
         else
           Helm.helm_repo_add("cilium","https://helm.cilium.io/")
           kubeconfig = KindManager.create_cluster("cilium-test", "cilium/cilium --version 1.10.5 --set operator.replicas=1", offline=false)
      end
      Log.info { "kubeconfig: #{kubeconfig}" }
      cilium_cnf_passed = CNFManager.cnf_to_new_cluster(config, kubeconfig)
      Log.info { "cilium_cnf_passed: #{cilium_cnf_passed}" }
      puts "CNF failed to install on Cilum CNI cluster".colorize(:red) unless cilium_cnf_passed

      emoji_security="🔓🔑"
      if calico_cnf_passed && cilium_cnf_passed 
        upsert_passed_task("cnf_compatible", "✔️  PASSED: CNF compatible with both Calico and Cilium #{emoji_security}")
      else
        upsert_failed_task("cnf_compatible", "✖️  FAILED: CNF not compatible with either Calico or Cillium #{emoji_security}")
      end
    ensure
      KindManager.delete_cluster("calico-test")
      KindManager.delete_cluster("cilium-test")
      ENV["KUBECONFIG"]="#{kubeconfig_orig}"
    end
end


