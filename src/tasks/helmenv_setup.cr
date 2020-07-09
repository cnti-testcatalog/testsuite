require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Sets up helm 3.1.1"
task "helm_local_install", ["cnf_directory_setup"] do |_, args|
  #TODO pass in version of helm
  LOGGING.info "helm_local_install" if check_verbose(args)
  current_dir = FileUtils.pwd
  LOGGING.debug current_dir if check_verbose(args)
  unless Dir.exists?("#{current_dir}/#{TOOLS_DIR}/helm")
    begin
      LOGGING.debug "pwd? : #{current_dir}" if check_verbose(args)
      LOGGING.debug "toolsdir : #{TOOLS_DIR}" if check_verbose(args)
      LOGGING.debug "full path?: #{current_dir.to_s}/#{TOOLS_DIR}/helm" if check_verbose(args)
      FileUtils.mkdir_p("#{current_dir}/#{TOOLS_DIR}/helm")
      wget = `wget https://get.helm.sh/helm-v3.1.1-linux-amd64.tar.gz -O #{current_dir}/#{TOOLS_DIR}/helm/helm-v3.1.1-linux-amd64.tar.gz`
      LOGGING.debug wget if check_verbose(args)
      tar = `cd #{current_dir}/#{TOOLS_DIR}/helm; tar -xvf #{current_dir}/#{TOOLS_DIR}/helm/helm-v3.1.1-linux-amd64.tar.gz`
      LOGGING.debug tar if check_verbose(args)
      helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
      LOGGING.debug helm if check_verbose(args)
      LOGGING.debug `#{helm} version` if check_verbose(args)
      stable_repo = `#{helm} repo add stable https://kubernetes-charts.storage.googleapis.com`
      LOGGING.debug stable_repo if check_verbose(args)

      #TODO grep for version.BuildInfo{Version:"v3.1.1", GitCommit:"afe70585407b420d0097d07b21c47dc511525ac8", GitTreeState:"clean", GoVersion:"go1.13.8"}
    ensure
      cd = `cd #{current_dir}`
      LOGGING.debug cd if check_verbose(args)
    end
  end
end

desc "Cleans up helm 3.1.1"
task "helm_local_cleanup"do |_, args|
  LOGGING.info "helm_local_cleanup" if check_verbose(args)
  current_dir = FileUtils.pwd
  rm = `rm -rf #{current_dir}/#{TOOLS_DIR}/helm`
  LOGGING.debug rm if check_verbose(args)
end
