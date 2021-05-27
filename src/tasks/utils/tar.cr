require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"

module TarClient
  TAR_REPOSITORY_DIR = "/tmp/repositories"
  TAR_MANIFEST_DIR = "/tmp/manifests"

  def self.tar(tarball_name, working_directory, source_file_or_directory, options="")
    #working_directory: directory to cd into before running the tar command
    LOGGING.info "TarClient.tar command: tar #{options} -czvf #{tarball_name} -C #{working_directory} #{source_file_or_directory}"
    # tar -czvf #{cnf_tarball_name} ./#{cnf_bin_asset_name}
    status = Process.run("tar #{options} -czvf #{tarball_name} -C #{working_directory} #{source_file_or_directory}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    LOGGING.info "TarClient.tar output: #{output.to_s}"
    LOGGING.info "TarClient.tar stderr: #{stderr.to_s}"
    {status: status, output: output, error: stderr}
  end
  def self.append(tarball_name, working_directory, source_file_or_directory, options="")
    #working_directory: directory to cd into before running the tar command
    LOGGING.info "TarClient.tar (append) command: tar #{options} -rf #{tarball_name} -C #{working_directory} #{source_file_or_directory}"
    status = Process.run("tar #{options} -rf #{tarball_name} -C #{working_directory} #{source_file_or_directory}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    LOGGING.info "TarClient.tar output: #{output.to_s}"
    LOGGING.info "TarClient.tar stderr: #{stderr.to_s}"
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

  def self.tar_helm_repo(command, output_file : String = "./airgapped.tar.gz")
    # TODO get the chart name out of the command
    # chaos-mesh/chaos-mesh --version 0.5.1
    repo = command.split(" ")[0]
    repo_dir = repo.gsub("/", "_")
    repo_path = "repositories/#{repo_dir}" 
    `rm -rf /tmp/#{repo_path} > /dev/null 2>&1`
    FileUtils.mkdir_p("/tmp/#{repo_path}")
    Helm.fetch("#{command} -d /tmp/#{repo_path}")
    helm_chart = Dir.entries("/tmp/#{repo_path}").first
    TarClient.append(output_file, "/tmp", "#{repo_path}")
  ensure
    `rm -rf /tmp/#{repo_path} > /dev/null 2>&1`
  end
  
  def self.tar_manifest(url, output_file : String = "./airgapped.tar.gz", prefix="")
    manifest_path = "manifests/" 
    `rm -rf /tmp/#{manifest_path} > /dev/null 2>&1`
    FileUtils.mkdir_p("/tmp/" + manifest_path)
    manifest_name = prefix + url.split("/").last 
    manifest_full_path = manifest_path + url.split("/").last
    LOGGING.info "manifest_name: #{manifest_name}"
    LOGGING.info "manifest_full_path: #{manifest_full_path}"
    Halite.get("#{url}") do |response| 
       File.open("/tmp/" + manifest_full_path, "w") do |file| 
         IO.copy(response.body_io, file)
       end
    end
    TarClient.append(output_file, "/tmp", manifest_full_path)
  ensure
    `rm -rf /tmp/#{manifest_path} > /dev/null 2>&1`
  end
end
