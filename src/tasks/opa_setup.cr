require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Sets up OPA in the K8s Cluster"
task "install_opa", ["helm_local_install", "create_namespace"] do |_, args|
  helm_install_args_list = [
    "--set auditInterval=1",
    "--set postInstall.labelNamespace.enabled=false",
    "-n #{TESTSUITE_NAMESPACE}"
  ]

  k8s_server_version = KubectlClient.server_version
  if !version_less_than(k8s_server_version, "1.25.0")
    helm_install_args_list.push("--set psp.enabled=false")
  end

  helm_install_args = helm_install_args_list.join(" ")

  Helm.helm_repo_add("gatekeeper", "https://open-policy-agent.github.io/gatekeeper/charts")
  begin
    Helm.install("#{helm_install_args} opa-gatekeeper gatekeeper/gatekeeper")
  rescue e : Helm::CannotReuseReleaseNameError
    stdout_warning "gatekeeper already installed"
  end

  File.write("enforce-image-tag.yml", ENFORCE_IMAGE_TAG)
  File.write("constraint_template.yml", CONSTRAINT_TEMPLATE)
  KubectlClient::Apply.file("constraint_template.yml")
  KubectlClient.wait("--for condition=established --timeout=300s crd/requiretags.constraints.gatekeeper.sh")
  KubectlClient::Apply.file("enforce-image-tag.yml")
end

desc "Uninstall OPA"
task "uninstall_opa" do |_, args|
  Log.for("verbose").info { "uninstall_opa" } if check_verbose(args)
  Helm.delete("opa-gatekeeper -n #{TESTSUITE_NAMESPACE}")
  KubectlClient::Delete.file("enforce-image-tag.yml")
  KubectlClient::Delete.file("constraint_template.yml")
end
