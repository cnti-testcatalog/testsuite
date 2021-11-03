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

      if args.named["offline"]?
           kubeconfig = KindManager.create_cluster("calico-test", "#{TarClient::TAR_DOWNLOAD_DIR}/calico.tar.gz")
         else
           current_dir = FileUtils.pwd 
           chart = "#{current_dir}/#{TOOLS_DIR}/calico.tar.gz"
           Halite.get("https://github.com/projectcalico/calico/releases/download/v3.20.1/tigera-operator-v3.20.1.tgz") do |response|
             File.write("#{chart}", response.body_io)
           end
           kubeconfig = KindManager.create_cluster("calico-test", "#{chart}")
      end
      Log.info { "kubeconfig: #{kubeconfig}" }
      calico_cnf_passed = CNFManager.cnf_to_new_cluster(config, kubeconfig)
      Log.info { "calico_cnf_passed: #{calico_cnf_passed}" }
      puts "CNF failed to install on Calico CNI cluster".colorize(:red) unless calico_cnf_passed


      if args.named["offline"]?
           kubeconfig = KindManager.create_cluster("cilium-test", "#{TarClient::TAR_REPOSITORY_DIR}/cilium_cilium --set operator.replicas=1")
         else

           kubeconfig = KindManager.create_cluster("cilium-test", "cilium/cilium --version 1.10.5 --set operator.replicas=1")
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
    end
  # end
end


