require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"


OPA_OFFLINE_DIR = "#{TarClient::TAR_REPOSITORY_DIR}/gatekeeper_gatekeeper"

desc "Sets up Kubescape in the K8s Cluster"
task "install_kubescape" do |_, args|
  url = "https://raw.githubusercontent.com/armosec/kubescape/v#{KUBESCAPE_VERSION}/install.sh"
  current_dir = FileUtils.pwd 
  unless Dir.exists?("#{current_dir}/#{TOOLS_DIR}/kubescape")
    FileUtils.mkdir_p("#{current_dir}/#{TOOLS_DIR}/kubescape") 
    write_file = "#{current_dir}/#{TOOLS_DIR}/kubescape/install.sh"
    Log.info { "url: #{url}" }
    Log.info { "write_file: #{write_file}" }
    resp = Halite.follow.get("#{url}") do |response| 
      File.write("#{write_file}", response.body_io)
    end 
    status = Process.run("#{current_dir}/#{TOOLS_DIR}/kubescape/install.sh", shell: true, output: stdout, error: stdout)
    Log.for("verbose").info { stdout }
  end
  #todo kubescape run wrapper
  #kubescape scan framework nsa --exclude-namespaces kube-system,kube-public
  #todo kubescape scrapper
end

desc "Uninstall OPA"
task "uninstall_opa" do |_, args|
  Log.for("verbose").info { "uninstall_opa" } if check_verbose(args)
  Helm.delete("opa-gatekeeper")
  KubectlClient::Delete.file("enforce-image-tag.yml")
  KubectlClient::Delete.file("constraint_template.yml")
end
