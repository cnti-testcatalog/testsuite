require "totem"
require "colorize"
# todo remove depedency
require "./cnf_manager.cr"
require "halite"
# todo remove depedency
require "./airgap_utils.cr"

# todo put in a separate library. it shold go under ./tools for now
module TarClient
  TAR_REPOSITORY_DIR = "/tmp/repositories"
  TAR_MANIFEST_DIR = "/tmp/manifests"
  TAR_DOWNLOAD_DIR = "/tmp/download"
  TAR_IMAGES_DIR = "/tmp/images"
  TAR_BIN_DIR = "/tmp/bin"
  TAR_TMP_BASE = "/tmp"
  TAR_MODIFY_DIR = "/tmp/modify_tar"

  def self.tar(tarball_name, working_directory, source_file_or_directory, options="")
    LOGGING.info "TarClient.tar command: tar #{options} -czvf #{tarball_name} -C #{working_directory} #{source_file_or_directory}"
    LOGGING.info "cding into #{working_directory} and tarring #{source_file_or_directory} into #{tarball_name}"
    LOGGING.info "#{tarball_name} exists?: #{File.exists?(tarball_name)}" 
    if File.exists?(tarball_name)
      LOGGING.info "#{tarball_name} contents (before tar): #{`tar -tvf #{tarball_name}`}"
    end
    # tar -czvf #{cnf_tarball_name} ./#{cnf_bin_asset_name}
    status = Process.run("tar #{options} -czvf #{tarball_name} -C #{working_directory} #{source_file_or_directory}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    LOGGING.info "TarClient.tar output: #{output.to_s}"
    LOGGING.info "TarClient.tar stderr: #{stderr.to_s}"
    LOGGING.info "#{tarball_name} contents (after tar): #{`tar -tvf #{tarball_name}`}"
    {status: status, output: output, error: stderr}
  end
  def self.append(tarball_name, working_directory, source_file_or_directory, options="")
    #working_directory: directory to cd into before running the tar command
    LOGGING.info "TarClient.tar (append) command: tar #{options} -rf #{tarball_name} -C #{working_directory} #{source_file_or_directory}"
    LOGGING.info "cding into #{working_directory} and tarring #{source_file_or_directory} into #{tarball_name}"
    LOGGING.info "#{tarball_name} exists?: #{File.exists?(tarball_name)}" 
    if File.exists?(tarball_name)
      LOGGING.info "#{tarball_name} contents (before tar): #{`tar -tvf #{tarball_name}`}"
    end

    status = Process.run("tar #{options} -rf #{tarball_name} -C #{working_directory} #{source_file_or_directory}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    LOGGING.info "TarClient.tar output: #{output.to_s}"
    LOGGING.info "TarClient.tar stderr: #{stderr.to_s}"
    LOGGING.info "#{tarball_name} contents (after tar): #{`tar -tvf #{tarball_name}`}"
    {status: status, output: output, error: stderr}
  end
  def self.untar(tarball_name, destination_directory, options="")
    LOGGING.info "TarClient.untar command: tar #{options} -xvf #{tarball_name} -C #{destination_directory}"
    # tar -xvf #{destination_cnf_dir}/exported_chart/#{Helm.chart_name(helm_chart)}-*.tgz" 
    # tar -xvf /tmp/kubernetes-server-linux-${platform}.tar.gz -C /tmp/kubernetes-${platform} 
    status = Process.run("tar #{options} -xvf #{tarball_name} -C #{destination_directory}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    LOGGING.info "TarClient.untar output: #{output.to_s}"
    LOGGING.info "TarClient.untar stderr: #{stderr.to_s}"
    {status: status, output: output, error: stderr}
  end

  # todo find wrapper
  def self.find(directory, wildcard="*.tar*", maxdepth="1", silent=true)
    LOGGING.debug("tar_file_name")
    LOGGING.debug("find: find #{directory} -maxdepth #{maxdepth} -name \"#{wildcard}\"")
    found_files = `find #{directory} -maxdepth #{maxdepth} -name "#{wildcard}"`.split("\n").select{|x| x.empty? == false}
    LOGGING.debug("find response: #{found_files}")
    if found_files.size == 0 && !silent
      raise "No files found!"
    end
    found_files
  end

  def self.helm_tar_dir(config_src)
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

  def self.helm_tar_name(config_src)
    FileUtils.mkdir_p(TAR_REPOSITORY_DIR)
    LOGGING.debug "helm_tar_name ls /tmp/repositories:" + `ls -al /tmp/repositories`
    tar_dir = helm_tar_dir(config_src)
    tgz_files = TarClient.find(tar_dir, "*.tgz*")
    tar_files = TarClient.find(tar_dir, "*.tar*") + tgz_files
    tar_name = ""
    tar_name = tar_files[0] if !tar_files.empty?
    LOGGING.info "tar_name: #{tar_name}"
    tar_name
  end

  def self.tar_info_by_config_src(config_src)
    FileUtils.mkdir_p(TAR_REPOSITORY_DIR)
    LOGGING.debug "tar_info_by_config_src ls /tmp/repositories:" + `ls -al /tmp/repositories`
    # chaos-mesh/chaos-mesh --version 0.5.1
    repo = config_src.split(" ")[0]
    repo_dir = repo.gsub("/", "_")
    chart_name = repo.split("/")[-1]
    repo_path = "repositories/#{repo_dir}" 
    tar_dir = "/tmp/#{repo_path}"
    tar_info = {repo: repo, repo_dir: repo_dir, chart_name: chart_name,
     repo_path: repo_path, tar_dir: tar_dir, tar_name: helm_tar_name(config_src)}
    LOGGING.info "tar_info: #{tar_info}"
    tar_info
  end

  def self.modify_tar!(tar_file)
    raise "Critical Error" if tar_file.empty? || tar_file == '/'
    tar_name = tar_file.split("/")[-1]
    FileUtils.mkdir_p(TAR_MODIFY_DIR)
    TarClient.untar(tar_file, TAR_MODIFY_DIR)
    yield TAR_MODIFY_DIR
    `rm #{tar_file}`
    file_list = `ls #{TAR_MODIFY_DIR}`.gsub("\n", " ") 
    TarClient.tar(tar_file, TAR_MODIFY_DIR, file_list)
    `rm -rf #{TAR_MODIFY_DIR}`
  end
  # todo modify_tar! << untars file, yields to block, retars, keep in tar module
  # todo tar_name_by_helm_chart << airgapp sandbox specific, put in airgap module
  # todo airgap_helm_chart << prepare a helm_chart tar file for deploment into an airgapped enviroment, put in airgap module
  # todo airgap_helm_directory << prepare a helm directory for deploment into an airgapped enviroment, put in airgap module
  # todo airgap_manifest_directory << prepare a manifest directory for deploment into an airgapped enviroment, put in airgap module
  #TODO move helm utilities into helm-tar utilty file or into helm file
  def self.tar_helm_repo(command, output_file : String = "./airgapped.tar.gz")
    LOGGING.info "tar_helm_repo command: #{command} output_file: #{output_file}"
    # get the chart name out of the command
    # chaos-mesh/chaos-mesh --version 0.5.1
    #
    tar_dir = helm_tar_dir(command)
    FileUtils.mkdir_p(tar_dir)
    Helm.fetch("#{command} -d #{tar_dir}")
    LOGGING.debug "ls #{tar_dir}:" + `ls -al #{tar_dir}`
    info = tar_info_by_config_src(command)
    repo = info[:repo]
    repo_dir = info[:repo_dir]
    chart_name = info[:chart_name]
    repo_path = info[:repo_path]
    tar_dir = info[:tar_dir]
    tar_name = info[:tar_name]

    LOGGING.debug "ls /tmp/repositories:" + `ls -al /tmp/repositories`
    LOGGING.debug "ls #{tar_dir}:" + `ls -al #{tar_dir}`
    TarClient.untar(tar_name, tar_dir)
    `rm #{tar_name}` if File.exists?(tar_name)
    LOGGING.debug "ls #{tar_dir}:" + `ls -al #{tar_dir}`
    # todo separate out into function that takes a directory name
    # todo call this in the cnf setup install when in offline mode
    template_files = TarClient.find(tar_dir, "*.yaml*", "100")
    LOGGING.debug "template_files: #{template_files}"
    # resp = yield template_files
    # AirGapUtils.image_pull_policy(template_files[0])
    template_files.map{|x| AirGapUtils.image_pull_policy(x)}
    # TODO look for yml as well
    # TODO handle recursive/dependend helm charts
    # TODO function for looping through all yml files in a directory
    # TODO open the current file if it is a yml file and change the manifest to use image_pull_policy
    helm_chart = Dir.entries("/tmp/#{repo_path}").first
    raise "Critical Error" if tar_dir.empty? || tar_dir == '/'
    # TarClient.append(tar_name, tar_dir, chart_name, "-z")
    TarClient.tar(tar_name, tar_dir, chart_name)
    #TODO rm client that checks path for /
    `rm -rf #{tar_dir}/#{chart_name}`
    TarClient.append(output_file, "/tmp", "#{repo_path}")
  ensure
    `rm -rf /tmp/#{repo_path} > /dev/null 2>&1`
  end
  
  #TODO create tar_helm_directory
  #TODO create tar_manifest_directory
  #TODO change to tar_manifest_by_url
  def self.tar_manifest(url, output_file : String = "./airgapped.tar.gz", prefix="")
    manifest_path = "manifests/" 
    `rm -rf /tmp/#{manifest_path} > /dev/null 2>&1`
    FileUtils.mkdir_p("/tmp/" + manifest_path)
    manifest_name = prefix + url.split("/").last 
    # manifest_full_path = manifest_path + url.split("/").last
    manifest_full_path = manifest_path + manifest_name 
    LOGGING.info "manifest_name: #{manifest_name}"
    LOGGING.info "manifest_full_path: #{manifest_full_path}"
    Halite.get("#{url}") do |response| 
      #TODO response.body_io to use image_pull_policy
       File.open("/tmp/" + manifest_full_path, "w") do |file| 
         IO.copy(response.body_io, file)
       end
    end
    TarClient.append(output_file, "/tmp", manifest_full_path)
  ensure
    `rm -rf /tmp/#{manifest_path} > /dev/null 2>&1`
  end

  def self.tar_file_by_url(url, append_file : String = "./downloaded.tar.gz", output_file="")
    download_path = "download/" 
    `rm -rf /tmp/#{download_path} > /dev/null 2>&1`
    FileUtils.mkdir_p("/tmp/" + download_path)
    if output_file.empty?
      download_name = url.split("/").last 
    else
      download_name = output_file
    end
    download_full_path = download_path + download_name
    LOGGING.info "download_name: #{download_name}"
    LOGGING.info "download_full_path: #{download_full_path}"
    Halite.get("#{url}") do |response| 
       File.open("/tmp/" + download_full_path, "w") do |file| 
         IO.copy(response.body_io, file)
       end
    end
    TarClient.append(append_file, "/tmp", download_full_path)
  ensure
    `rm -rf /tmp/#{download_path} > /dev/null 2>&1`
  end

end
