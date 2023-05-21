require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

FALCO_OFFLINE_DIR = "#{TarClient::TAR_REPOSITORY_DIR}/falcosecurity_falco"

desc "Install Falco"
task "install_falco" do |_, args|
  # helm = Helm::BinarySingleton.helm
  File.write("falco_rule.yaml", FALCO_RULES)
  chart_version = "--version 3.1.5"
  begin
    if args.named["offline"]?
      Log.info { "install falco offline mode" }
      helm_chart = Dir.entries(FALCO_OFFLINE_DIR).first
      Helm.install("falco --set driver.kind=ebpf #{chart_version} -f ./falco_rule.yaml -n #{TESTSUITE_NAMESPACE} #{FALCO_OFFLINE_DIR}/#{helm_chart}")
    else
      Helm.helm_repo_add("falcosecurity","https://falcosecurity.github.io/charts")
      # needs ebpf parameter for precompiled module
      Helm.install("falco --set driver.kind=ebpf #{chart_version} -f ./falco_rule.yaml -n #{TESTSUITE_NAMESPACE} falcosecurity/falco")
    end
  rescue Helm::CannotReuseReleaseNameError
    Log.info { "Falco already installed" }
  end
end

desc "Uninstall Falco"
task "uninstall_falco" do |_, args|
  Log.for("verbose").info { "uninstall_falco" } if check_verbose(args)
  Helm.delete("-n #{TESTSUITE_NAMESPACE} falco")
end
