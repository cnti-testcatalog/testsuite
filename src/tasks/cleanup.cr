require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Cleans up the CNF Conformance test suite, the K8s cluster, and upstream projects"
# task "cleanup", ["samples_cleanup", "results_yml_cleanup"] do  |_, args|
task "cleanup", ["samples_cleanup"] do  |_, args|
end

desc "Cleans up the CNF Conformance sample projects"
task "samples_cleanup", ["sample_coredns_cleanup", "cleanup_sample_coredns", "bad_helm_cnf_cleanup", "sample_privileged_cnf_non_whitelisted_cleanup", "sample_privileged_cnf_whitelisted_cleanup", "sample_coredns_bad_liveness_cleanup", "sample_coredns_source_cleanup", "sample_generic_cnf_cleanup"] do  |_, args|
  if args.named["force"]? && args.named["force"] == "true"
    force = true 
  else
    force = false
  end
  `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample-large-cnf`
  `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample-bad-helm-deploy-repo`
  `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample-bad-helm-repo`
  `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample-bad_helm_coredns-cnf`
  `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample-coredns-cnf-bad-chart`
  `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample_coredns_chart_directory`
  # get rid of lingering coredns pods
  if force
  `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample-coredns-cnf force=true`
  end
end

task "tools_cleanup", ["helm_local_cleanup", "sonobuoy_cleanup"] do  |_, args|
end

task "cleanup_all", ["cleanup_samples", "tools_cleanup"] do  |_, args|
end

task "results_yml_cleanup" do |_, args|
  if File.exists?("#{LOGFILE}")
    rm = `rm #{LOGFILE}`
    puts rm if check_verbose(args)
  end
end
