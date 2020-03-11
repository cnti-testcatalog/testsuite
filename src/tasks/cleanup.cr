require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Cleans up the CNF Conformance test suite, the K8s cluster, and upstream projects"
task "cleanup", ["samples_cleanup"] do  |_, args|
end

task "samples_cleanup", ["sample_coredns_cleanup", "bad_helm_cnf_cleanup", "sample_privileged_cnf_non_whitelisted_cleanup", "sample_privileged_cnf_whitelisted_cleanup"] do  |_, args|
end

task "tools_cleanup", ["helm_local_cleanup"] do  |_, args|
end

task "cleanup_all", ["cleanup_samples", "tools_cleanup"] do  |_, args|
end
