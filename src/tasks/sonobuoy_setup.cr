require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils.cr"
require "http/client"

desc "Sets up Sonobuoy in the K8s Cluster"
task "install_sonobuoy" do |_, args|
  #TODO: Fetch version dynamically
  # k8s_version = HTTP::Client.get("https://storage.googleapis.com/kubernetes-release/release/stable.txt").body.chomp.split(".")[0..1].join(".").gsub("v", "") 
  k8s_version = "0.17.2"
  puts k8s_version if check_verbose(args)
  current_dir = FileUtils.pwd 
  puts current_dir if check_verbose(args)
  unless Dir.exists?("#{current_dir}/#{TOOLS_DIR}/sonobuoy")
    begin
      puts "pwd? : #{current_dir}" if check_verbose(args)
      puts "toolsdir : #{TOOLS_DIR}" if check_verbose(args)
      puts "full path?: #{current_dir.to_s}/#{TOOLS_DIR}/sonobuoy" if check_verbose(args)
      FileUtils.mkdir_p("#{current_dir}/#{TOOLS_DIR}/sonobuoy") 
      curl = `VERSION="#{k8s_version}" OS=linux ; curl -L "https://github.com/vmware-tanzu/sonobuoy/releases/download/v${VERSION}/sonobuoy_${VERSION}_${OS}_amd64.tar.gz" --output #{current_dir}/#{TOOLS_DIR}/sonobuoy/sonobuoy.tar.gz`
      puts curl if check_verbose(args)
       `tar -xzf #{current_dir}/#{TOOLS_DIR}/sonobuoy/sonobuoy.tar.gz -C #{current_dir}/#{TOOLS_DIR}/sonobuoy/ && \
       chmod +x #{current_dir}/#{TOOLS_DIR}/sonobuoy/sonobuoy && \
       rm #{current_dir}/#{TOOLS_DIR}/sonobuoy/sonobuoy.tar.gz`
      sonobuoy = "#{current_dir}/#{TOOLS_DIR}/sonobuoy/sonobuoy"
      puts sonobuoy if check_verbose(args)
      puts `#{sonobuoy} version` if check_verbose(args)
    end
  end
end

