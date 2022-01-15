require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Sets up api snoop"
task "install_apisnoop" do |_, args|
  Log.for("verbose").info { "install_apisnoop" }
  ApiSnoop.new(FileUtils.pwd).install()
end
