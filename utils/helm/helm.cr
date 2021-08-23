require "colorize"

BinarySingleton = BinaryReference.new
class BinaryReference 
  # CNF_DIR = "cnfs"
  @helm: String?

  def global_helm_installed?
    ghelm = helm_global_response
    global_helm_version = helm_v3_version(ghelm)
    if (global_helm_version)
      true
    else
      false
    end
  end

  def helm_global_response(verbose=false)
    Process.run("helm version", shell: true, output: stdout = IO::Memory.new, error: stderr = IO::Memory.new)
    stdout.to_s
  end

  def helm_v3_version(helm_response)
    # version.BuildInfo{Version:"v3.1.1", GitCommit:"afe70585407b420d0097d07b21c47dc511525ac8", GitTreeState:"clean", GoVersion:"go1.13.8"}
    helm_v3 = helm_response.match /BuildInfo{Version:\"(v([0-9]{1,3}[\.]){1,2}[0-9]{1,3}).+"/
    helm_v3 && helm_v3.not_nil![1]
  end

  # Get helm directory
  def helm
    @helm ||= global_helm_installed? ? "helm" : raise "Global install of Helm not found"
  end
end

module Helm

  #TODO move to kubectlclient
  DEPLOYMENT="Deployment"
  SERVICE="Service"
  POD="Pod"
  CHART_YAML = "Chart.yaml"

  enum InstallParams
    InstallMethod
    ConfigSrc
    ReleaseName
  end
   
  enum InstallMethod
    HelmChart
    HelmDirectory
    ManifestDirectory 
    Invalid
  end


  def self.install_method_by_config_src(install_method : InstallMethod, config_src : String) : InstallMethod
    LOGGING.info "helm install_method_by_config_src"
    LOGGING.info "config_src: #{config_src}"
    helm_chart_file = "#{config_src}/#{Helm::CHART_YAML}"
    LOGGING.info "looking for potential helm_chart_file: #{helm_chart_file}: file exists?: #{File.exists?(helm_chart_file)}"
    # todo use process run
    ls_al = `ls -alR config_src #{config_src}`
    ls_al = `ls -alR helm_chart_file #{helm_chart_file}`

    if !Dir.exists?(config_src) 
      LOGGING.info "install_method_by_config_src helm_chart selected"
      InstallMethod::HelmChart
    elsif File.exists?(helm_chart_file)
      LOGGING.info "install_method_by_config_src helm_directory selected"
      InstallMethod::HelmDirectory
    elsif Dir.exists?(config_src) 
      LOGGING.info "install_method_by_config_src manifest_directory selected"
      InstallMethod::ManifestDirectory
    else
      InstallMethod::Invalid
    end
  end

  # Utilities for manifest files that are not templates or have been converted already
  # todo move into own file
  module Manifest
    def self.parse_manifest_as_ymls(template_file_name="cnfs/temp_template.yml")
      LOGGING.info "parse_manifest_as_ymls template_file_name: #{template_file_name}"
      templates = File.read(template_file_name)
      split_template = templates.split("---")
      ymls = split_template.map { | template |
        #TODO strip out NOTES
        YAML.parse(template)
        # compact seems to have problems with yaml::any
      }.reject{|x|x==nil}
      LOGGING.debug "read_template ymls: #{ymls}"
      ymls
    end

    def self.manifest_ymls_from_file_list(manifest_file_list)
      ymls = manifest_file_list.map do |x|
        parse_manifest_as_ymls(x)
      end
      ymls.flatten
    end

    def self.manifest_file_list(manifest_directory, silent=false)
      LOGGING.info("manifest_file_list")
      LOGGING.info "manifest_directory: #{manifest_directory}"
      if manifest_directory && !manifest_directory.empty? && manifest_directory != "/"
        LOGGING.info("find: find #{manifest_directory}/ -name *.yml -o -name *.yaml")
        manifests = `find #{manifest_directory}/ -name "*.yml" -o -name "*.yaml"`.split("\n").select{|x| x.empty? == false}
        LOGGING.info("find response: #{manifests}")
        if manifests.size == 0 && !silent
          raise "No manifest ymls found in the #{manifest_directory} directory!"
        end
        manifests
      else
        [] of String
      end
    end
    def self.manifest_containers(manifest_yml)
      LOGGING.debug "manifest_containers: #{manifest_yml}"
      manifest_yml.dig?("spec", "template", "spec", "containers")
    end
    LOGGING = LogginGenerator.new
    class LogginGenerator
      macro method_missing(call)
        if {{ call.name.stringify }} == "debug"
          Log.debug {{{call.args[0]}}}
        end
        if {{ call.name.stringify }} == "info"
          Log.info {{{call.args[0]}}}
        end
        if {{ call.name.stringify }} == "warn"
          Log.warn {{{call.args[0]}}}
        end
        if {{ call.name.stringify }} == "error"
          Log.error {{{call.args[0]}}}
        end
        if {{ call.name.stringify }} == "fatal"
          Log.fatal {{{call.args[0]}}}
        end
      end
    end
  end


  # Use helm to apply the helm values file to the helm chart templates to create a complete manifest
  # Helm uses manifest files that can be jinja templates
  def self.generate_manifest_from_templates(release_name, helm_chart, output_file="cnfs/temp_template.yml")
    LOGGING.debug "generate_manifest_from_templates"
    # todo remove my guilt 
    helm = BinarySingleton.helm
    LOGGING.info "Helm::generate_manifest_from_templates command: #{helm} template #{release_name} #{helm_chart} > #{output_file}"
    # Helm template works with either a chart or a directory
    ls_al = `ls -alR #{helm_chart}`
    LOGGING.info "(before generate) ls -alR #{helm_chart}: #{ls_al}"
    ls_al = `ls -alR cnfs`
    LOGGING.info "(before generate) ls -alR cnfs: #{ls_al}"
    LOGGING.debug "generate_manifest_from_templates ls -alR #{helm_chart}: #{ls_al}" 
    # template_resp = `#{helm} template #{release_name} #{helm_chart} > #{output_file}`
    resp = Helm.template(release_name, helm_chart, output_file)
    ls_al = `ls -alR #{helm_chart}`
    LOGGING.info "(after generate) ls -alR #{helm_chart}: #{ls_al}"
    ls_al = `ls -alR cnfs`
    LOGGING.info "(after generate) ls -alR cnfs: #{ls_al}"
    # input_content = File.read(output_file) 
    LOGGING.debug "generate_manifest_from_templates output_file: #{output_file}"
    [resp[:status].success?, output_file]
  end

  def self.workload_resource_by_kind(ymls : Array(YAML::Any), kind)
    LOGGING.info "workload_resource_by_kind kind: #{kind}"
    LOGGING.debug "workload_resource_by_kind ymls: #{ymls}"
    resources = ymls.select{|x| x["kind"]?==kind}.reject! {|x|
        # reject resources that contain the 'helm.sh/hook: test' annotation
      LOGGING.debug "x[metadata]?: #{x["metadata"]?}"
      LOGGING.debug "x[metadata][annotations]?: #{x["metadata"]? && x["metadata"]["annotations"]?}"
      x.dig?("metadata","annotations","helm.sh/hook")
      }
    # end
    LOGGING.debug "resources: #{resources}"
    resources
  end

  def self.all_workload_resources(yml : Array(YAML::Any))
    resources = KubectlClient::WORKLOAD_RESOURCES.map { |k,v|
      Helm.workload_resource_by_kind(yml, v)
    }.flatten
    LOGGING.debug "all resource: #{resources}"
    resources
  end

  def self.workload_resource_names(resources : Array(YAML::Any) )
    resource_names = resources.map do |x|
      x["metadata"]["name"]
    end
    LOGGING.debug "resource names: #{resource_names}"
    resource_names
  end

  def self.workload_resource_kind_names(resources : Array(YAML::Any) )
    resource_names = resources.map do |x|
      {kind: x["kind"], name: x["metadata"]["name"]}
    end
    LOGGING.debug "resource names: #{resource_names}"
    resource_names
  end

  def self.helm_repo_add(helm_repo_name, helm_repo_url)
    helm = BinarySingleton.helm
    LOGGING.info "helm_repo_add: helm repo add command: #{helm} repo add #{helm_repo_name} #{helm_repo_url}"
    stdout = IO::Memory.new
    stderror = IO::Memory.new
    begin
      process = Process.new("#{helm}", ["repo", "add", "#{helm_repo_name}", "#{helm_repo_url}"], output: stdout, error: stderror)
      status = process.wait
      helm_resp = stdout.to_s
      error = stderror.to_s
      LOGGING.info "error: #{error}"
      LOGGING.info "helm_resp (add): #{helm_resp}"
    rescue
      LOGGING.info "helm repo add command critically failed: #{helm} repo add #{helm_repo_name} #{helm_repo_url}"
    end
    # Helm version v3.3.3 gave us a surprise
    if helm_resp =~ /has been added|already exists/ || error =~ /has been added|already exists/
      ret = true
    else
      ret = false
    end
    ret
  end

  def self.helm_gives_k8s_warning?(verbose=false)
    helm = BinarySingleton.helm
    stdout = IO::Memory.new
    stderror = IO::Memory.new
    begin
      process = Process.new("#{helm}", ["list"], output: stdout, error: stderror)
      status = process.wait
      helm_resp = stdout.to_s
      error = stderror.to_s
      LOGGING.info "error: #{error}"
      LOGGING.info "helm_resp (add): #{helm_resp}"
      # Helm version v3.3.3 gave us a surprise
      if (helm_resp + error) =~ /WARNING: Kubernetes configuration file is/
        stdout_failure("For this version of helm you must set your K8s config file permissions to chmod 700") if verbose
        true
      else
        false
      end
    rescue ex
      stdout_failure("Please use newer version of helm")
      true
    end
  end

  def self.local_helm_path
    current_dir = FileUtils.pwd
    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
  end

  def self.chart_name(helm_chart_repo)
    helm_chart_repo.split("/").last
  end

  def self.template(release_name, helm_chart_or_directory, output_file="cnfs/temp_template.yml")
    helm = BinarySingleton.helm
    LOGGING.info "helm command: #{helm} template #{release_name} #{helm_chart_or_directory} > #{output_file}"
    status = Process.run("#{helm} template #{release_name} #{helm_chart_or_directory} > #{output_file}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    LOGGING.info "Helm.template output: #{output.to_s}"
    LOGGING.info "Helm.template stderr: #{stderr.to_s}"
    {status: status, output: output, error: stderr}
  end

  def self.install(cli)
    helm = BinarySingleton.helm
    LOGGING.info "helm command: #{helm} install #{cli}"
    status = Process.run("#{helm} install #{cli}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    LOGGING.info "Helm.install output: #{output.to_s}"
    LOGGING.info "Helm.install stderr: #{stderr.to_s}"
    {status: status, output: output, error: stderr}
  end

  def self.delete(cli)
    helm = BinarySingleton.helm
    Log.info { "helm command: #{helm} delete #{cli}" }
    status = Process.run("#{helm} delete #{cli}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    Log.info { "Helm.install delete: #{output.to_s}" }
    Log.info { "Helm.install delete: #{stderr.to_s}" }
    {status: status, output: output, error: stderr}
  end

  def self.pull(cli)
    helm = BinarySingleton.helm
    LOGGING.info "helm command: #{helm} pull #{cli}"
    status = Process.run("#{helm} pull #{cli}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    LOGGING.info "Helm.install output: #{output.to_s}"
    LOGGING.info "Helm.install stderr: #{stderr.to_s}"
    {status: status, output: output, error: stderr}
  end

  def self.fetch(cli)
    helm = BinarySingleton.helm
    LOGGING.info "helm command: #{helm} fetch #{cli}"
    status = Process.run("#{helm} fetch #{cli}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    LOGGING.info "Helm.fetch output: #{output.to_s}"
    LOGGING.info "Helm.fetch stderr: #{stderr.to_s}"
    {status: status, output: output, error: stderr}
  end

  LOGGING = LogginGenerator.new
  class LogginGenerator
    macro method_missing(call)
      if {{ call.name.stringify }} == "debug"
        Log.debug {{{call.args[0]}}}
      end
      if {{ call.name.stringify }} == "info"
        Log.info {{{call.args[0]}}}
      end
      if {{ call.name.stringify }} == "warn"
        Log.warn {{{call.args[0]}}}
      end
      if {{ call.name.stringify }} == "error"
        Log.error {{{call.args[0]}}}
      end
      if {{ call.name.stringify }} == "fatal"
        Log.fatal {{{call.args[0]}}}
      end
    end
  end
end
