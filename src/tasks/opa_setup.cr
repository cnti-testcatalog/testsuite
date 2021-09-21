require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Sets up OPA in the K8s Cluster"
task "install_opa" do |_, args|
  response = String::Builder.new
  Process.run("echo installing opa", shell: true) do |proc|
    Helm.helm_repo_add("gatekeeper","https://open-policy-agent.github.io/gatekeeper/charts")
    Helm.install("--set auditInterval=1 opa-gatekeeper gatekeeper/gatekeeper")

    # `helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts`
    # `helm install --set auditInterval=1 opa-gatekeeper gatekeeper/gatekeeper`

    while line = proc.output.gets
      response << line
      VERBOSE_LOGGING.info "#{line}" if check_verbose(args)
    end
  end
  File.write("enforce-image-tag.yml", ENFORCE_IMAGE_TAG)
  File.write("constraint_template.yml", CONSTRAINT_TEMPLATE)
  KubectlClient::Apply.file("enforce-image-tag.yml")
  KubectlClient::Apply.file("constraint_template.yml")
end

desc "Uninstall OPA"
task "uninstall_opa" do |_, args|
  Log.for("verbose").info { "uninstall_opa" } if check_verbose(args)
  Helm.delete("opa-gatekeeper")
  KubectlClient::Delete.file("enforce-image-tag.yml")
  KubectlClient::Delete.file("constraint_template.yml")
end
