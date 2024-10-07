require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Cleans up the CNF test suite, the K8s cluster, and upstream projects"
# task "cleanup", ["samples_cleanup", "results_yml_cleanup"] do  |_, args|
task "cleanup", ["samples_cleanup"] do  |_, args|
end

desc "Cleans up the CNF Test Suite sample projects"
task "samples_cleanup" do  |_, args|
  if args.named["force"]? && args.named["force"] == "true"
    force = true 
  else
    force = false
  end

  CNFManager::Task.all_cnfs_task_runner(args) do |task_args, config|
    Log.info { "Task args: #{task_args.inspect}" }
    next unless task_args["cnf-config"]?

    cnf_config_file = task_args["cnf-config"].as(String)
    cnf_config_file = CNFManager.ensure_cnf_testsuite_yml_path(cnf_config_file)

    config = CNFInstall::Config.parse_cnf_config_from_file(cnf_config_file)
    install_method = config.dynamic.install_method
    if install_method[0] == CNFInstall::InstallMethod::ManifestDirectory
      installed_from_manifest = true
    else
      installed_from_manifest = false
    end

    Log.info { "CNF CONFIG: #{cnf_config_file}" }
    CNFManager.sample_cleanup(
      config_file: cnf_config_file,
      force: force,
      installed_from_manifest: installed_from_manifest,
      verbose: check_verbose(args)
    )
    nil
  end
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
task "cleanup_all", ["samples_cleanup", "tools_cleanup"] do  |_, args|
end

task "results_yml_cleanup" do |_, args|
  if CNFManager::Points::Results.file_exists?
    File.delete(CNFManager::Points::Results.file)
    Log.for("verbose").info { "Deleted results file at #{CNFManager::Points::Results.file}" } if check_verbose(args)
  end
end
