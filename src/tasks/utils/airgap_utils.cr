# coding: utf-8
require "./find.cr"
# To avoid circular dependencies:
# airgap uses airgaputils
# airgap uses tar
# tar uses airgaputils
# airgaputils uses find
module AirGapUtils
  TAR_REPOSITORY_DIR = "/tmp/repositories"

  def self.image_pull_policy_config_file?(install_method, config_src, release_name)
    LOGGING.info "image_pull_policy_config_file"
    yml = [] of Array(YAML::Any)
    case install_method
    when Helm::InstallMethod::ManifestDirectory
      file_list = Helm::Manifest.manifest_file_list(config_src, silent=false)
      yml = Helm::Manifest.manifest_ymls_from_file_list(file_list)
    when Helm::InstallMethod::HelmChart, Helm::InstallMethod::HelmDirectory
      Helm.template(release_name, config_src, output_file="cnfs/temp_template.yml") 
      yml = Helm::Manifest.parse_manifest_as_ymls(template_file_name="cnfs/temp_template.yml")
    else
      raise "config source error: #{install_method}"
    end
    container_image_pull_policy?(yml)
  end

  def self.container_image_pull_policy?(yml : Array(YAML::Any))
    LOGGING.info "container_image_pull_policy"
    containers  = yml.map { |y|
      mc = Helm::Manifest.manifest_containers(y)
      mc.as_a? if mc
    }.flatten.compact
    LOGGING.debug "containers : #{containers}"
    found_all = true 
    containers.flatten.map do |x|
      LOGGING.debug "container x: #{x}"
      ipp = x.dig?("imagePullPolicy")
      image = x.dig?("image")
      LOGGING.debug "ipp: #{ipp}"
      LOGGING.debug "image: #{image.as_s}" if image
      parsed_image = DockerClient.parse_image(image.as_s) if image
      LOGGING.debug "parsed_image: #{parsed_image}"
      # if there is no image pull policy, any image that does not have a tag will
      # force a call out to the default image registry
      if ipp == nil && (parsed_image && parsed_image["tag"] == "latest")
        LOGGING.info "ipp or tag not found with ipp: #{ipp} and parsed_image: #{parsed_image}"
        found_all = false
      end 
    end
    LOGGING.info "found_all: #{found_all}"
    found_all
  end


  def self.image_pull_policy(file, output_file="")
    input_content = File.read(file) 
    output_content = input_content.gsub(/(.*imagePullPolicy:)(.*)/,"\\1 Never")

    # LOGGING.debug "pull policy found?: #{input_content =~ /(.*imagePullPolicy:)(.*)/}"
    # LOGGING.debug "output_content: #{output_content}"
    if output_file.empty?
      input_content = File.write(file, output_content) 
    else
      input_content = File.write(output_file, output_content) 
    end
    #
    #TODO find out why this doesn't work
    # LOGGING.debug "after conversion: #{File.read(file)}"
  end

  def self.tar_name_by_helm_chart(config_src : String)
    FileUtils.mkdir_p(TAR_REPOSITORY_DIR)
    LOGGING.debug "tar_name_by_helm_chart ls /tmp/repositories:" + `ls -al /tmp/repositories`
    tar_dir = helm_tar_dir(config_src)
    tgz_files = Find.find(tar_dir, "*.tgz*")
    tar_files = Find.find(tar_dir, "*.tar*") + tgz_files
    tar_name = ""
    tar_name = tar_files[0] if !tar_files.empty?
    LOGGING.info "tar_name: #{tar_name}"
    tar_name
  end

  def self.tar_info_by_config_src(config_src : String)
    FileUtils.mkdir_p(TAR_REPOSITORY_DIR)
    LOGGING.debug "tar_info_by_config_src ls /tmp/repositories:" + `ls -al /tmp/repositories`
    # chaos-mesh/chaos-mesh --version 0.5.1
    repo = config_src.split(" ")[0]
    repo_dir = repo.gsub("/", "_")
    chart_name = repo.split("/")[-1]
    repo_path = "repositories/#{repo_dir}" 
    tar_dir = "/tmp/#{repo_path}"
    tar_info = {repo: repo, repo_dir: repo_dir, chart_name: chart_name,
     repo_path: repo_path, tar_dir: tar_dir, tar_name: tar_name_by_helm_chart(config_src)}
    LOGGING.info "tar_info: #{tar_info}"
    tar_info
  end

  def self.helm_tar_dir(config_src : String)
    FileUtils.mkdir_p(TAR_REPOSITORY_DIR)
    LOGGING.debug "helm_tar_dir ls /tmp/repositories:" + `ls -al /tmp/repositories`
    # chaos-mesh/chaos-mesh --version 0.5.1
    repo = config_src.split(" ")[0]
    repo_dir = repo.gsub("/", "_")
    chart_name = repo.split("/")[-1]
    repo_path = "repositories/#{repo_dir}" 
    tar_dir = "/tmp/#{repo_path}"
    LOGGING.info "helm_tar_dir: #{tar_dir}"
    tar_dir
  end


end
