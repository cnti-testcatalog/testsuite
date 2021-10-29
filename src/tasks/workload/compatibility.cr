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
  if args.named["offline"]? || args.raw.includes? "offline"
      puts "offline mode cni_compatible skipped".colorize(:yellow) 
  else
    CNFManager::Task.task_runner(args) do |args, config|
      VERBOSE_LOGGING.info "cni_compatible" if check_verbose(args)

      kubeconfig = KindManager.create_cluster("calico-test", "projectcalico/tigera-operator")
      Log.info { "kubeconfig: #{kubeconfig}" }

      calico_cnf_passed = CNFManager.cnf_to_new_cluster(config, kubeconfig)
      Log.info { "calico_cnf_passed: #{calico_cnf_passed}" }
      puts "CNF failed to install on Calico CNI cluster".colorize(:red) unless calico_cnf_passed

      kubeconfig = KindManager.create_cluster("cilium-test", "cilium/cilium --version 1.10.5 --set operator.replicas=1")
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
  end
end


