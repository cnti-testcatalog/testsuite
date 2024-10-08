require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Sets up the CNF test suite, the K8s cluster, and upstream projects"

task "setup", ["version", "helm_local_install", "prereqs", "create_namespace", "configuration_file_setup", "install_apisnoop", "install_sonobuoy", "install_chart_testing", "cnf_testsuite_setup", "install_kind"] do  |_, args|
  stdout_success "Setup complete"
end

task "create_namespace" do |_, args|
  ensure_kubeconfig!
  if KubectlClient::Create.namespace(TESTSUITE_NAMESPACE)
    stdout_success "Created #{TESTSUITE_NAMESPACE} namespace on the Kubernetes cluster"
  else
    stdout_failure "Could not create #{TESTSUITE_NAMESPACE} namespace on the Kubernetes cluster"
  end
rescue e : KubectlClient::Create::AlreadyExistsError
  stdout_success "#{TESTSUITE_NAMESPACE} namespace already exists on the Kubernetes cluster"
end

task "configuration_file_setup" do |_, args|
  Log.for("verbose").info { "configuration_file_setup" } if check_verbose(args)
  CNFManager::Points.create_points_yml
end

task "validate_config" do |_, args|
  if args.named["cnf-config"]?
    config = CNFInstall::Config.parse_cnf_config_from_file(args.named["cnf-config"].to_s)
    puts "Successfully validated CNF config"
    Log.info {"Config: #{config.inspect}"}
  else
    stdout_failure "cnf-config parameter needed"
    exit 1
  end
end
