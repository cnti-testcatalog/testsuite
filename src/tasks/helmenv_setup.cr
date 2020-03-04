require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils.cr"

desc "Sets up helm 3.1.1"
task "helm_local_install", ["cnf_directory_setup"] do |_, args|
  #TODO pass in version of helm
  current_dir = FileUtils.pwd 
  puts current_dir if check_verbose(args)
  unless Dir.exists?("#{current_dir}/#{TOOLS_DIR}/helm")
    begin
      puts "pwd? : #{current_dir}" if check_verbose(args)
      puts "toolsdir : #{TOOLS_DIR}" if check_verbose(args)
      puts "full path?: #{current_dir.to_s}/#{TOOLS_DIR}/helm" if check_verbose(args)
      FileUtils.mkdir_p("#{current_dir}/#{TOOLS_DIR}/helm") 
      wget = `wget https://get.helm.sh/helm-v3.1.1-linux-amd64.tar.gz -O #{current_dir}/#{TOOLS_DIR}/helm/helm-v3.1.1-linux-amd64.tar.gz`
      puts wget if check_verbose(args)
      tar = `cd #{current_dir}/#{TOOLS_DIR}/helm; tar -xvf #{current_dir}/#{TOOLS_DIR}/helm/helm-v3.1.1-linux-amd64.tar.gz`
      puts tar if check_verbose(args)
      helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
      puts helm if check_verbose(args)
      puts `#{helm} version` if check_verbose(args)
      stable_repo = `#{helm} repo add stable https://kubernetes-charts.storage.googleapis.com`
      puts stable_repo if check_verbose(args)

      #TODO grep for version.BuildInfo{Version:"v3.1.1", GitCommit:"afe70585407b420d0097d07b21c47dc511525ac8", GitTreeState:"clean", GoVersion:"go1.13.8"} 
    ensure
      cd = `cd #{current_dir}`
      puts cd if check_verbose(args)
    end
  end
end

desc "Cleans up helm 3.1.1"
task "helm_local_cleanup"do |_, args|
  current_dir = FileUtils.pwd 
  rm = `rm -rf #{current_dir}/#{TOOLS_DIR}/helm`
  puts rm if check_verbose(args)
end
