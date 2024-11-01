require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Cleans up the CNF test suite, the K8s cluster, and upstream projects"
task "cleanup", ["cnf_cleanup"] do  |_, args|
end

desc "Cleans up the CNF Test Suite helper tools and containers"
task "tools_cleanup", [
    "sonobuoy_cleanup",
    "uninstall_chaosmesh",
    "uninstall_litmus",
    "uninstall_dockerd",
    "uninstall_kubescape",
    "uninstall_cluster_tools",
    "uninstall_opa",
 
    # Helm needs to be uninstalled last to allow other uninstalls to use helm if necessary.
    # Check this issue for details - https://github.com/cncf/cnf-testsuite/issues/1586
    "helm_local_cleanup"
  ] do  |_, args|
end

desc "Cleans up the CNF Test Suite sample projects, helper tools, and containers"
task "cleanup_all", ["uninstall_cnf", "tools_cleanup"] do  |_, args|
end

task "results_yml_cleanup" do |_, args|
  if CNFManager::Points::Results.file_exists?
    File.delete(CNFManager::Points::Results.file)
    Log.for("verbose").info { "Deleted results file at #{CNFManager::Points::Results.file}" } if check_verbose(args)
  end
end
