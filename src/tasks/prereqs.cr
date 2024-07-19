require "sam"
require "file_utils"
require "colorize"
require "totem"
require "helm"
# require "./utils/system_information/wget.cr"
# require "./utils/system_information/curl.cr"
require "./utils/system_information/clusterctl.cr"

task "prereqs" do |_, args|
  verbose = check_verbose(args)
  
  helm_ok = Helm::SystemInfo.helm_installation_info(verbose) && !Helm.helm_gives_k8s_warning?(true)
  kubectl_ok = KubectlClient.installation_found?(verbose)
  git_ok = GitClient.installation_found?

  checks = [
    helm_ok,
    kubectl_ok,
    git_ok
  ]

  if checks.includes?(false)
    stdout_failure "Setup failed. Some prerequisites are missing. Please install all of the prerequisites before continuing."
    exit 1
  else
    stdout_success "All prerequisites found."
  end
end
