require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Install Fluentd"
task "install_fluentd" do |_, args|
  FluentD.install
end

desc "Uninstall Fluentd"
task "uninstall_fluentd" do |_, args|
  FluentD.uninstall
end
