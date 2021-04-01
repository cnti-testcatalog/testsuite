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

  if (helm_installation.includes?("helm found") &&
      !Helm.helm_gives_k8s_warning?(true)) &
      # wget_installation.includes?("wget found") &
      # curl_installation.includes?("curl found") &
      kubectl_installation.includes?("kubectl found") &
      git_installation.includes?("git found")
  
      verbose = check_verbose(args)
      # clusterctl_installation(verbose).includes?("clusterctl found") && # not necessary for end users at this time

      stdout_success "All prerequisites found."
  else
    stdout_failure "Setup failed. Some prerequisites are missing. Please install all of the prerequisites before continuing."
    exit 1
  end
end
