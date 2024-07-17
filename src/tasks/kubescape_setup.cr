require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"
require "retriable"

desc "Sets up Kubescape in the K8s Cluster"
task "install_kubescape", ["kubescape_framework_download"] do |_, args|
  Log.info {"install_kubescape"}

  version_file = "#{tools_path}/kubescape/.kubescape_version"
  installed_kubescape_version = read_version_file(version_file)

  FileUtils.mkdir_p("#{tools_path}/kubescape")
  if !File.exists?("#{tools_path}/kubescape/kubescape") || installed_kubescape_version != KUBESCAPE_VERSION
    write_file = "#{tools_path}/kubescape/kubescape"
    Log.info { "write_file: #{write_file}" }
    Log.info { "kubescape install" }
    url = "https://github.com/armosec/kubescape/releases/download/v#{KUBESCAPE_VERSION}/kubescape-ubuntu-latest"
    Log.info { "url: #{url}" }
    Retriable.retry do
      HttpHelper.download("#{url}","#{write_file}")
      stderr = IO::Memory.new
      status = Process.run("chmod +x #{write_file}", shell: true, output: stderr, error: stderr)
      success = status.success?
      raise "Unable to make #{write_file} executable" if success == false
    end

    File.write(version_file, KUBESCAPE_VERSION)
  end
end

desc "Kubescape framework download"
task "kubescape_framework_download" do |_, args|
  Log.info { "kubescape_framework_download" }
  current_dir = FileUtils.pwd 
  # Download framework file using Github token if the GITHUB_TOKEN env var is present

  version_file = "#{tools_path}/kubescape/.kubescape_framework_version"
  installed_framework_version = read_version_file(version_file)
  FileUtils.mkdir_p("#{tools_path}/kubescape")

  framework_path = "#{tools_path}/kubescape/nsa.json"
  if !File.exists?(framework_path) || installed_framework_version != KUBESCAPE_FRAMEWORK_VERSION
    asset_url = "https://github.com/armosec/regolibrary/releases/download/v#{KUBESCAPE_FRAMEWORK_VERSION}/nsa"

    HttpHelper.download_auth(asset_url, framework_path)
    File.write(version_file, KUBESCAPE_FRAMEWORK_VERSION)
  end
end

desc "Kubescape Scan"
task "kubescape_scan", ["install_kubescape"] do |_, args|
  Kubescape.scan
end

desc "Uninstall Kubescape"
task "uninstall_kubescape" do |_, args|
  current_dir = FileUtils.pwd 
  Log.for("verbose").info { "uninstall_kubescape" } if check_verbose(args)
  FileUtils.rm_rf("#{tools_path}/kubescape")
end
