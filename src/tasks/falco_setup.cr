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
  helm_options = ENV["FALCO_HELM_OPTS"]?
  if helm_options.nil?
    helm_options = "--set driver.kind=ebpf"
  end

  # Use different helm chart version for CI
  if ENV["FALCO_ENV"]? == "CI"
    chart_version = "--version 1.15.7"

    # 1. Because the CI uses an old version the helm key values are different too.
    # 2. CI does not need support for FALCO_HELM_OPTS env var.
    helm_options = "--set ebpf.enabled=true"
    helm_options = "#{helm_options} --set image.repository=conformance/falco"
    helm_options = "#{helm_options} --set image.tag=0.29.1"
  end

  begin
    if args.named["offline"]?
      Log.info { "install falco offline mode" }
      helm_chart = Dir.entries(FALCO_OFFLINE_DIR).first
      Helm.install("falco #{chart_version} -f ./falco_rule.yaml #{helm_options} -n #{TESTSUITE_NAMESPACE} #{FALCO_OFFLINE_DIR}/#{helm_chart}")
    else
      Helm.helm_repo_add("falcosecurity","https://falcosecurity.github.io/charts")
      # needs ebpf parameter for precompiled module
      Helm.install("falco #{chart_version} -f ./falco_rule.yaml #{helm_options} -n #{TESTSUITE_NAMESPACE} falcosecurity/falco")
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
