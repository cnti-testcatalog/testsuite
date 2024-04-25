require "sam"
require "json"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"
require "retriable"

desc "Sets up Kubescape in the K8s Cluster"
task "install_kubescape", ["kubescape_framework_download"] do |_, args|
  Log.info {"install_kubescape"}

  # kubescape binary path
  kubescape_path = "#{tools_path}/kubescape/kubescape"

  # Check if the "kubescape" binary exists
  if File.exists?(kubescape_path)
    # Execute the command
    output = `#{kubescape_path} version 2>/dev/null | sed 's/^.*v//'`.chomp

    # Check if the output matches the desired string
    if output != KUBESCAPE_VERSION.to_s
      # Delete the folder
      FileUtils.rm_rf(kubescape_path)
      Log.info { "kubescape binary in wrong version, it was deleted" }
      Log.info { "expected version was #{output} but #{KUBESCAPE_VERSION} was found" }
    else
      Log.info { "kubescape binary in correct version, kept untouched" }
    end
  else
    Log.info { "kubescape binary not found" }
  end

  # version = `curl --silent "https://api.github.com/repos/armosec/kubescape/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
  FileUtils.mkdir_p("#{tools_path}/kubescape")
  unless File.exists?("#{tools_path}/kubescape/kubescape")
    write_file = "#{tools_path}/kubescape/kubescape"
    Log.info { "write_file: #{write_file}" }
    if args.named["offline"]?
        Log.info { "kubescape install offline mode" }
      `cp #{TarClient::TAR_DOWNLOAD_DIR}/kubescape-ubuntu-latest #{write_file}`
      `cp #{TarClient::TAR_DOWNLOAD_DIR}/nsa.json #{tools_path}/kubescape/`
      stderr = IO::Memory.new
      status = Process.run("chmod +x #{write_file}", shell: true, output: stderr, error: stderr)
      success = status.success?
      raise "Unable to make #{write_file} executable" if success == false
    else
      Log.info { "kubescape install online mode" }
      url = "https://github.com/armosec/kubescape/releases/download/v#{KUBESCAPE_VERSION}/kubescape-ubuntu-latest"
      Log.info { "url: #{url}" }
      Retriable.retry do

        HttpHelper.download("#{url}","#{write_file}")

        stderr = IO::Memory.new
        status = Process.run("chmod +x #{write_file}", shell: true, output: stderr, error: stderr)
        success = status.success?
        raise "Unable to make #{write_file} executable" if success == false
      end
    end
  end
end

desc "Kubescape framework download"
task "kubescape_framework_download" do |_, args|
  Log.info { "checking kubescape_framework version" }
  FileUtils.mkdir_p("#{tools_path}/kubescape")
  framework_path = "#{tools_path}/kubescape/nsa.json"

  if File.exists?(framework_path)
    json_string = File.read(framework_path)
    json = JSON.parse(json_string)
    version = json["version"]
    Log.info {" #{version} from nsa.json should match to v#{KUBESCAPE_FRAMEWORK_VERSION} "}
    if version != "v#{KUBESCAPE_FRAMEWORK_VERSION}".to_s
      # Delete kubescape framework
      FileUtils.rm_rf(framework_path)
      Log.info { "kubescape framework in wrong version, it was deleted" }
    end
  end

  Log.info { "kubescape_framework_download" }
  current_dir = FileUtils.pwd 
  # Download framework file using Github token if the GITHUB_TOKEN env var is present

  unless File.exists?(framework_path)
    asset_url = "https://github.com/armosec/regolibrary/releases/download/v#{KUBESCAPE_FRAMEWORK_VERSION}/nsa"

    HttpHelper.download_auth(asset_url, framework_path)
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
