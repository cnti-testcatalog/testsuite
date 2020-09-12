require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/system_information/helm.cr"
require "./utils/system_information/wget.cr"
require "./utils/system_information/curl.cr"
require "./utils/system_information/kubectl.cr"
require "./utils/system_information/clusterctl.cr"

task "prereqs" do  |_, args|
  verbose = check_verbose(args)
  if helm_installation(verbose).includes?("helm found") &&
      wget_installation(verbose).includes?("wget found") &&
      curl_installation(verbose).includes?("curl found") &&
      # clusterctl_installation(verbose).includes?("clusterctl found") && # not necessary for end users at this time
      kubectl_installation(verbose).includes?("kubectl found")
      stdout_success "All prerequisites found."
  else
    stdout_failure "Setup failed. Some prerequisites are missing. Please install all of the prerequisites before continuing."
    exit 1
  end
end

