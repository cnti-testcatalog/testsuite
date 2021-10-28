require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Uninstall LitmusChaos"
task "uninstall_litmus" do |_, args|
    uninstall_chaosengine_cmd = "kubectl delete chaosengine --all --all-namespaces"
    status = Process.run(
        uninstall_chaosengine_cmd,
        shell: true,
        output: stdout = IO::Memory.new,
        error: stderr = IO::Memory.new
    )
    if args.named["offline"]?
      Log.info { "install litmus offline mode" }
      KubectlClient::Delete.file("#{OFFLINE_MANIFESTS_PATH}/litmus-operator-v#{LitmusManager::Version}.yaml")
    else
      KubectlClient::Delete.file("https://litmuschaos.github.io/litmus/litmus-operator-v#{LitmusManager::Version}.yaml")
    end
    Log.info { "#{stdout}" if check_verbose(args) }
    Log.info { "#{stderr}" if check_verbose(args) }
end
