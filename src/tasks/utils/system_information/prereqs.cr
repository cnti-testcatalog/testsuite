require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./helm.cr"

task "prereqs" do  |_, args|
  helm_installations
end

