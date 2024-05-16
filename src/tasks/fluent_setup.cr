require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Install FluentD"
task "install_fluentd" do |_, args|
  FluentManagement.install("fluentd")
end

desc "Uninstall FluentD"
task "uninstall_fluentd" do |_, args|
  FluentManagement.uninstall("fluentd")
end

desc "Install FluentDBitnami"
task "install_fluentdbitnami" do |_, args|
  FluentManagement.install("fluentdbitnami")
end

desc "Uninstall FluentDBitnami"
task "uninstall_fluentdbitnami" do |_, args|
  FluentManagement.uninstall("fluentdbitnami")
end

desc "Install FluentBit"
task "install_fluentbit" do |_, args|
  FluentManagement.install("fluent-bit")
end

desc "Uninstall FluentBit"
task "uninstall_fluentbit" do |_, args|
  FluentManagement.uninstall("fluent-bit")
end