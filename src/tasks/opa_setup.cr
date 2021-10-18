require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"


OPA_OFFLINE_DIR = "#{TarClient::TAR_REPOSITORY_DIR}/gatekeeper_gatekeeper"

desc "Sets up OPA in the K8s Cluster"
task "install_opa" do |_, args|
  if args.named["offline"]?
    LOGGING.info "Intalling OPA Gatekeeper in Offline Mode"
    chart = Dir.entries(OPA_OFFLINE_DIR).first
    Helm.install("--set auditInterval=1 --set postInstall.labelNamespace.enabled=false opa-gatekeeper #{OPA_OFFLINE_DIR}/#{chart}")
  else
    Helm.helm_repo_add("gatekeeper", "https://open-policy-agent.github.io/gatekeeper/charts")
    begin
      Helm.install("--set auditInterval=1 opa-gatekeeper gatekeeper/gatekeeper")
    rescue e : Helm::CannotReuseReleaseNameError
      stdout_warning "gatekeeper already installed"
    end
  end
    File.write("enforce-image-tag.yml", ENFORCE_IMAGE_TAG)
    File.write("constraint_template.yml", CONSTRAINT_TEMPLATE)
    KubectlClient::Apply.file("constraint_template.yml")
    KubectlClient.wait("--for condition=established --timeout=60s crd/requiretags.constraints.gatekeeper.sh")
    KubectlClient::Apply.file("enforce-image-tag.yml")
end

desc "Uninstall OPA"
task "uninstall_opa" do |_, args|
  Log.for("verbose").info { "uninstall_opa" } if check_verbose(args)
  Helm.delete("opa-gatekeeper")
  KubectlClient::Delete.file("enforce-image-tag.yml")
  KubectlClient::Delete.file("constraint_template.yml")
end
