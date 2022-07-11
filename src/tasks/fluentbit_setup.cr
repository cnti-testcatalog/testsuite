require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Install FluentBit"
task "install_fluentbit" do |_, args|
  FluentBit.install
end

desc "Uninstall FluentBit"
task "uninstall_fluentbit" do |_, args|
  FluentBit.uninstall
end
