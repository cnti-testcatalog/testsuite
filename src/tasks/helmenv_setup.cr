require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"
require "http/client"

desc "Sets up helm 3.8.2"
task "helm_local_install", ["cnf_directory_setup"] do |_, args|
  Log.for("verbose").info { "helm_local_install" } if check_verbose(args)
  # check if helm is installed
  # if proper version of helm installed, don't install
  if SystemInfo::Helm.global_helm_installed? && !ENV.has_key?("force_install")
    Log.info { "Globally installed helm satisfies required version. Skipping local helm install." }
  else
    current_dir = FileUtils.pwd
    Log.for("verbose").debug { current_dir } if check_verbose(args)
    arch = "linux-amd64"

    FileUtils.mkdir_p("#{current_dir}/#{TOOLS_DIR}/helm")
    unless File.exists?("#{current_dir}/#{TOOLS_DIR}/helm/#{arch}/helm")
      begin
        if check_verbose(args)
          Log.for("verbose").debug { "pwd? : #{current_dir}" }
          Log.for("verbose").debug { "toolsdir : #{TOOLS_DIR}" }
          Log.for("verbose").debug { "full path?: #{current_dir.to_s}/#{TOOLS_DIR}/helm" }
        end

        HttpHelper.download("https://get.helm.sh/helm-v3.8.2-#{arch}.tar.gz","#{current_dir}/#{TOOLS_DIR}/helm/helm-v3.8.2-#{arch}.tar.gz")

        TarClient.untar(
          "#{current_dir}/#{TOOLS_DIR}/helm/helm-v3.8.2-#{arch}.tar.gz",
          "#{current_dir}/#{TOOLS_DIR}/helm"
        )

        helm = BinarySingleton.helm
        if check_verbose(args)
          stdout = IO::Memory.new
          status = Process.run("#{helm} version", output: stdout, error: stdout)
          Log.for("verbose").debug { stdout }
        end

        #TODO what is this for?
        stable_repo = Helm.helm_repo_add("stable", "https://cncf.gitlab.io/stable")
        Log.for("verbose").debug { "stable repo add: #{stable_repo}" } if check_verbose(args)

        #TODO grep for specific version e.g. version.BuildInfo{Version:"v3.1.1", GitCommit:"afe70585407b420d0097d07b21c47dc511525ac8", GitTreeState:"clean", GoVersion:"go1.13.8"} 
      end
    end
  end
  # `#{BinarySingleton.helm} repo add stable https://cncf.gitlab.io/stable`
end

desc "Cleans up helm 3.8.2"
task "helm_local_cleanup"do |_, args|
  Log.for("verbose").info { "helm_local_cleanup" } if check_verbose(args)
  current_dir = FileUtils.pwd 
  FileUtils.rm_rf("#{current_dir}/#{TOOLS_DIR}/helm")
end
