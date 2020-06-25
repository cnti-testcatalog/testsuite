require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Sets up the CNF Conformance test suite, the K8s cluster, and upstream projects"
task "setup", ["prereqs", "configuration_file_setup", "install_opa" , "install_api_snoop", "install_sonobuoy", "install_chart_testing", "helm_local_install", "cnf_conformance_setup"] do  |_, args|
  puts "Setup complete".colorize(:green) 
end

task "configuration_file_setup" do |_, args|
  LOGGING.info "configuration_file_setup" if check_verbose(args)
  create_points_yml
end

