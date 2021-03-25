require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Uninstall LitmusChaos"
task "uninstall_litmus" do |_, args|
    uninstall_chaosengine = `kubectl delete chaosengine --all --all-namespaces`
    litmus_uninstall = `kubectl delete -f https://litmuschaos.github.io/litmus/litmus-operator-v1.13.2.yaml`
    puts "#{uninstall_chaosengine}" if check_verbose(args)
    puts "#{litmus_uninstall}" if check_verbose(args)
end
