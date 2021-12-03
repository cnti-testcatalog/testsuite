require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"
require "retriable"

desc "Sets up Kubescape in the K8s Cluster"
task "install_kubescape", ["kubescape_framework_download"] do |_, args|
  Log.info {"install_kubescape"}
  # version = `curl --silent "https://api.github.com/repos/armosec/kubescape/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
  current_dir = FileUtils.pwd 
  FileUtils.mkdir_p("#{current_dir}/#{TOOLS_DIR}/kubescape") 
  unless File.exists?("#{current_dir}/#{TOOLS_DIR}/kubescape/kubescape")
    write_file = "#{current_dir}/#{TOOLS_DIR}/kubescape/kubescape"
    Log.info { "write_file: #{write_file}" }
    if args.named["offline"]?
        Log.info { "kubescape install offline mode" }
      `cp #{TarClient::TAR_DOWNLOAD_DIR}/kubescape-ubuntu-latest #{write_file}`
      `cp #{TarClient::TAR_DOWNLOAD_DIR}/nsa.json #{current_dir}/#{TOOLS_DIR}/kubescape/`
      stderr = IO::Memory.new
      status = Process.run("chmod +x #{write_file}", shell: true, output: stderr, error: stderr)
      success = status.success?
      raise "Unable to make #{write_file} executable" if success == false
    else
      Log.info { "kubescape install online mode" }
      url = "https://github.com/armosec/kubescape/releases/download/v#{KUBESCAPE_VERSION}/kubescape-ubuntu-latest"
      Log.info { "url: #{url}" }
      Retriable.retry do
        resp = Halite.follow.get("#{url}") do |response| 
          File.write("#{write_file}", response.body_io)
        end 
        Log.debug {"resp: #{resp}"}
        case resp.status_code
        when 403, 404
          raise "Unable to download: #{url}" 
        end
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
  current_dir = FileUtils.pwd 
  # Download framework file using Github token if the GITHUB_TOKEN env var is present

  FileUtils.mkdir_p("#{current_dir}/#{TOOLS_DIR}/kubescape") 
  framework_path = "#{current_dir}/#{TOOLS_DIR}/kubescape/nsa.json"
  unless File.exists?(framework_path)
    asset_url = "https://github.com/armosec/regolibrary/releases/download/v#{KUBESCAPE_FRAMEWORK_VERSION}/nsa"
    if ENV.has_key?("GITHUB_TOKEN")
      Halite.auth("Bearer #{ENV["GITHUB_TOKEN"]}").get(asset_url) do |response|
        File.write(framework_path, response.body_io)
      end
    else
      Halite.get(asset_url) do |response|
        File.write(framework_path, response.body_io)
      end
    end
    Log.info { "KUBESCAPE_DEBUG_URL: #{asset_url}" }
    Log.info { "KUBESCAPE_DEBUG" }
    `head #{framework_path}`
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
  FileUtils.rm_rf("#{current_dir}/#{TOOLS_DIR}/kubescape")
end
