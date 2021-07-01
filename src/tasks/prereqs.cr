require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/system_information/helm.cr"
# require "./utils/system_information/wget.cr"
# require "./utils/system_information/curl.cr"
require "./utils/system_information/kubectl.cr"
require "./utils/system_information/git.cr"
require "./utils/system_information/clusterctl.cr"

task "prereqs" do  |_, args|
  verbose = check_verbose(args)
  helm_condition = helm_installation(verbose).includes?("helm found") && !Helm.helm_gives_k8s_warning?(true)
  kubectl_checks_output = kubectl_installation(verbose)

  # Should be true if kubectl is found
  kubectl_existance = kubectl_checks_output.includes?("kubectl found")

  checks = [
    helm_condition,
    kubectl_existance
  ]

  # git installation is optional for offline mode
  if !args.named["offline"]?
    checks << git_installation.includes?("git found")
  end

  if checks.includes?(false)
    stdout_failure "Setup failed. Some prerequisites are missing. Please install all of the prerequisites before continuing."
    exit 1
  else
    stdout_success "All prerequisites found."
  end
end
