require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Install Fluentd bitnami"
task "install_fluentdbitnami" do |_, args|
  FluentDBitnami.install
end

desc "Uninstall Fluentd bitnami"
task "uninstall_fluentdbitnami" do |_, args|
  FluentDBitnami.uninstall
end
