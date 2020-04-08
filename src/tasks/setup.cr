require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Sets up the CNF Conformance test suite, the K8s cluster, and upstream projects"
task "setup", ["results_yml_setup", "install_opa" , "install_api_snoop", "install_sonobuoy", "install_chart_testing", "helm_local_install", "cnf_conformance_setup"] do  |_, args|
end

task "results_yml_setup" do |_, args|
  create_results_yml
end

