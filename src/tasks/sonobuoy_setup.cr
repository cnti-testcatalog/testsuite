require "sam"
require "file_utils"
require "colorize"
require "totem"
require "http/client"
require "halite" 
require "./utils/utils.cr"

def sonobuoy_details(cmd_path : String)
  Log.for("verbose").debug { cmd_path }
  stdout = IO::Memory.new
  status = Process.run("#{cmd_path} version", shell: true, output: stdout, error: stdout)
  Log.for("verbose").info { stdout }
end

desc "Sets up Sonobuoy in the K8s Cluster"
task "install_sonobuoy" do |_, args|
  #TODO: Fetch version dynamically
  # k8s_version = HTTP::Client.get("https://storage.googleapis.com/kubernetes-release/release/stable.txt").body.chomp.split(".")[0..1].join(".").gsub("v", "") 
  # TODO make k8s_version dynamic
  # TODO use kubectl version and grab the server version
  # k8s_version = "0.19.0"
  Log.for("verbose").debug { SONOBUOY_K8S_VERSION } if check_verbose(args)
  current_dir = FileUtils.pwd 
  Log.for("verbose").debug { current_dir } if check_verbose(args)
  unless Dir.exists?("#{tools_path}/sonobuoy")
    Log.for("verbose").debug { "toolsdir : #{tools_path}" } if check_verbose(args)
    Log.for("verbose").debug { "full path?: #{tools_path}/sonobuoy" } if check_verbose(args)
    FileUtils.mkdir_p("#{tools_path}/sonobuoy")
    # curl = `VERSION="#{LITMUS_K8S_VERSION}" OS=linux ; curl -L "https://github.com/vmware-tanzu/sonobuoy/releases/download/v${VERSION}/sonobuoy_${VERSION}_${OS}_amd64.tar.gz" --output #{tools_path}/sonobuoy/sonobuoy.tar.gz`
    # os="linux"
    url = "https://github.com/vmware-tanzu/sonobuoy/releases/download/v#{SONOBUOY_K8S_VERSION}/sonobuoy_#{SONOBUOY_K8S_VERSION}_#{SONOBUOY_OS}_amd64.tar.gz"
    write_file = "#{tools_path}/sonobuoy/sonobuoy.tar.gz"
    Log.info { "url: #{url}" }
    Log.info { "write_file: #{write_file}" }
    # todo change this to work with rel 
    # todo I think http get doesn't do follows and thats why we use halite here, that's sad. Shouldn't need to do a follow to download a file though?
     #  i think any url can do a redirect  ....
    # it could be that http.get 'just works' now.  keyword just
    HttpHelper.download("#{url}","#{write_file}")
    `tar -xzf #{tools_path}/sonobuoy/sonobuoy.tar.gz -C #{tools_path}/sonobuoy/ && \
     chmod +x #{tools_path}/sonobuoy/sonobuoy && \
     rm #{tools_path}/sonobuoy/sonobuoy.tar.gz`
    sonobuoy = "#{tools_path}/sonobuoy/sonobuoy"
    sonobuoy_details(sonobuoy) if check_verbose(args)
  end
end

desc "Cleans up Sonobuoy"
task "sonobuoy_cleanup" do |_, args|
  current_dir = FileUtils.pwd 
  sonobuoy = "#{tools_path}/sonobuoy/sonobuoy"
  status = Process.run(
    "#{sonobuoy} delete --wait 2>&1",
    shell: true,
    output: stdout = IO::Memory.new,
    error: stderr = IO::Memory.new
  )
  Log.for("verbose").info { stdout } if check_verbose(args)
  FileUtils.rm_rf("#{tools_path}/sonobuoy")
end

