require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/system_information/helm.cr"
require "./utils/system_information/wget.cr"
require "./utils/system_information/curl.cr"

task "prereqs" do  |_, args|
  if helm_installation.includes?("helm found") &&
      wget_installation.includes?("wget found") &&
      curl_installation.includes?("curl found") &&
      kubectl_installation.includes?("kubectl found")
    puts "All prerequisites found.".colorize(:green)
  else
    puts "Setup failed. Some prerequisites are missing. Please install all of the prerequisites before continuing.".colorize(:red)
    exit 1
  end
end

