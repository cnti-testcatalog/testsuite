require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Alias for cnf_uninstall"
task "uninstall", ["cnf_uninstall"] do  |_, args|
end

desc "Cleans up the CNF Test Suite helper tools and containers"
task "tools_uninstall", [
    "uninstall_sonobuoy",
    "uninstall_chaosmesh",
    "uninstall_litmus",
    "uninstall_dockerd",
    "uninstall_kubescape",
    "uninstall_cluster_tools",
    "uninstall_opa",
 
    # Helm needs to be uninstalled last to allow other uninstalls to use helm if necessary.
    # Check this issue for details - https://github.com/cncf/cnf-testsuite/issues/1586
    "uninstall_local_helm"
  ] do  |_, args|
end

desc "Cleans up the CNF Test Suite sample projects, helper tools, and containers"
task "uninstall_all", ["cnf_uninstall", "tools_uninstall"] do  |_, args|
end

task "delete_results" do |_, args|
  if CNFManager::Points::Results.file_exists?
    File.delete(CNFManager::Points::Results.file)
    Log.for("verbose").info { "Deleted results file at #{CNFManager::Points::Results.file}" } if check_verbose(args)
  end
end
