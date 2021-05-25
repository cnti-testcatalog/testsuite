require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"

module TarClient
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

  def self.tar_helm_repo(repo, output_file : String = "./airgapped.tar.gz")
    repo_dir = repo.gsub("/", "_")
    repo_path = "repositories/#{repo_dir}" 
    `rm -rf /tmp/#{repo_path} > /dev/null 2>&1`
    FileUtils.mkdir_p("/tmp/#{repo_path}")
    Helm.fetch("#{repo} -d /tmp/#{repo_path}")
    helm_chart = Dir.entries("/tmp/#{repo_path}").first
    TarClient.append(output_file, "/tmp", "#{repo_path}")
  end
end
