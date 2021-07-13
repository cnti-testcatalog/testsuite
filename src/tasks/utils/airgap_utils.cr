# coding: utf-8
require "./find.cr"
# To avoid circular dependencies:
# airgap uses airgaputils
# airgap uses tar
# tar uses airgaputils
# airgaputils uses find
module AirGapUtils
  TAR_REPOSITORY_DIR = "/tmp/repositories"

  #  doesnt work 1) todo loop through all directories and subdirectories
  #  doesnt work todo loop through all files in a directory
  #  doesnt work todo template_files = Find.find(directory, "*.yaml*", "100") 
  #  doesnt work todo template_files = Find.find(directory, "*.yml*", "100") 
  #  doesnt work todo parse file if has yaml and yml extension
  #  doesnt work    template_files.map do |x| 
  #  doesnt work todo Helm::Manifest.parse_manifest_as_ymls(template_file_name="cnfs/temp_template.yml")
  #  doesnt work    end
  #  doesnt work or
  
  # 1a) todo (if helm/helmdirectory) export a template file of the cnf (helm/helm directory/manifest)
  # todo helm template(release_name, helm_chart_or_directory, output_file="cnfs/temp_template.yml") 
  # todo Helm::Manifest.parse_manifest_as_ymls(template_file_name="cnfs/temp_template.yml")
  # todo (if manifest directory)
  # todo  Helm::Manifest..manifest_file_list(manifest_directory, silent=false)
  # todo  Helm::Manifest..manifest_ymls_from_file_list(manifest_file_list)
  #
  # 2) todo get the containers array from yml file or workload resource
  # todo Helm::Manifest.manifest_containers(manifest_yml)
  # todo if imagepullpolicy exists true; else false
  # todo if all directories/all workload resources are true then no warning; else warning

  def self.image_pull_policy_config_file?(config_file)
    LOGGING.info "image_pull_policy_config_src"
    config = CNFManager.parsed_config_file(config_file)
    sandbox_config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file), airgapped: true, generate_tar_mode: false) 
    release_name = sandbox_config.cnf_config[:release_name]
    install_method = CNFManager.cnf_installation_method(config)
    yml = [] of Array(YAML::Any)
    case install_method[0] 
    when :manifest_directory
      file_list = Helm::Manifest.manifest_file_list(install_method[1], silent=false)
      yml = Helm::Manifest.manifest_ymls_from_file_list(file_list)
    when :helm_chart, :helm_directory
      Helm.template(release_name, install_method[1], output_file="cnfs/temp_template.yml") 
      yml = Helm::Manifest.parse_manifest_as_ymls(template_file_name="cnfs/temp_template.yml")
    else
      raise "config source error: #{install_method}"
    end
    container_image_pull_policy?(yml)
  end

  def self.container_image_pull_policy?(yml : Array(YAML::Any))
    LOGGING.info "container_image_pull_policy"
    containers  = yml.map { |y|
      Helm::Manifest.manifest_containers(y)
    }.flatten
    found = true 
    containers.map do |x|
      ipp = x.dig?("imagePullPolicy") if x
      LOGGING.debug "ipp: #{ipp}"
      unless ipp
        found = false
      end 
    end
    found 
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
