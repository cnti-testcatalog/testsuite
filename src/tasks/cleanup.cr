require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Cleans up the CNF Conformance test suite, the K8s cluster, and upstream projects"
task "cleanup", ["samples_cleanup", "results_yml_cleanup"] do  |_, args|
end

task "samples_cleanup", ["sample_coredns_cleanup", "cleanup_sample_coredns", "bad_helm_cnf_cleanup", "sample_privileged_cnf_non_whitelisted_cleanup", "sample_privileged_cnf_whitelisted_cleanup", "sample_coredns_bad_liveness_cleanup", "sample_coredns_source_cleanup"] do  |_, args|
end

task "tools_cleanup", ["helm_local_cleanup", "sonobuoy_cleanup"] do  |_, args|
end

task "cleanup_all", ["cleanup_samples", "tools_cleanup"] do  |_, args|
end

task "results_yml_cleanup" do |_, args|
  rm = `rm results.yml`
  puts rm if check_verbose(args)
end
