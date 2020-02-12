require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Sets up the CNF Conformance test suite, the K8s cluster, and upstream projects"
task "setup", ["install_opa" , "install_api_snoop", "install_sonobuoy", "install_chart_testing"] do  |_, args|
end

