require "sam"
require "file_utils"
require "colorize"
require "totem"
require "yaml"
require "./utils/utils.cr"

task "cnf_setup", ["helm_local_install", "create_namespace"] do |_, args|
  Log.for("verbose").info { "cnf_setup" } if check_verbose(args)
  Log.for("verbose").debug { "args = #{args.inspect}" } if check_verbose(args)
  cli_hash = CNFManager.sample_setup_cli_args(args)
  config_file =  cli_hash[:config_file]

  # To avoid undefined behavior, only one CNF can be set up at any time.
  if CNFManager.cnf_installed?
    stdout_warning "A CNF is already set up. Setting up multiple CNFs is not allowed."
    stdout_warning "To set up a new CNF, clean up the existing one by running: cnf_cleanup cnf-path=#{CNFManager.cnf_config_list.first}"
    exit 0
  end

  if ClusterTools.install
    stdout_success "ClusterTools installed"
  else
    stdout_failure "The ClusterTools installation timed out. Please check the status of the cluster-tools pods."
    exit 1
  end

  stdout_success "cnf setup start"
  CNFManager.sample_setup(cli_hash)
  stdout_success "cnf setup complete"
end

task "cnf_cleanup" do |_, args|
  Log.for("verbose").info { "cnf_cleanup" } if check_verbose(args)
  Log.for("verbose").debug { "args = #{args.inspect}" } if check_verbose(args)
  if args.named.keys.includes? "cnf-config"
    cnf = args.named["cnf-config"].as(String)
  elsif args.named.keys.includes? "cnf-path"
    cnf = args.named["cnf-path"].as(String)
  else
    stdout_failure "Error: You must supply either cnf-config or cnf-path"
    exit 1
	end
  Log.debug { "cnf_cleanup cnf: #{cnf}" } if check_verbose(args)
  if args.named["force"]? && args.named["force"] == "true"
    force = true 
  else
    force = false
  end
  config = CNFInstall::Config.parse_cnf_config_from_file(CNFManager.ensure_cnf_testsuite_yml_path(cnf))
  install_method = config.dynamic.install_method
  if install_method[0] == CNFInstall::InstallMethod::ManifestDirectory
    installed_from_manifest = true
  else
    installed_from_manifest = false
  end
  CNFManager.sample_cleanup(config_file: cnf, force: force, installed_from_manifest: installed_from_manifest, verbose: check_verbose(args))
end

task "CNFManager.helm_repo_add" do |_, args|
  Log.for("verbose").info { "CNFManager.helm_repo_add" } if check_verbose(args)
  Log.for("verbose").debug { "args = #{args.inspect}" } if check_verbose(args)
  if args.named["cnf-config"]? || args.named["yml-file"]?
    CNFManager.helm_repo_add(args: args)
  else
    CNFManager.helm_repo_add
  end

end

task "generate_config" do |_, args|
  interactively_create_config()
end

#TODO force all cleanups to use generic cleanup
task "bad_helm_cnf_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-bad_helm_coredns-cnf", verbose: true)
end

task "sample_privileged_cnf_whitelisted_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample_whitelisted_privileged_cnf", verbose: true)
end

task "sample_privileged_cnf_non_whitelisted_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample_privileged_cnf", verbose: true)
end

task "sample_coredns_bad_liveness_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample_coredns_bad_liveness", verbose: true)
end
task "sample_coredns_source_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-coredns-cnf-source", verbose: true)
end

task "sample_generic_cnf_cleanup" do |_, args|
  CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
end

def interactively_create_config
  new_config = {
    config_version: CNFInstall::Config::ConfigVersion::Latest.to_s,
    deployments: {
      helm_charts: [] of Hash(String, String),
      helm_dirs: [] of Hash(String, String),
      manifests: [] of Hash(String, String)
    }
  }

  loop do
    puts "Select deployment type:"
    puts "1. Helm Chart"
    puts "2. Helm Directory"
    puts "3. Manifest Directory"
    puts "4. Finish and save configuration"
    choice = prompt("Enter your choice (1-4): ")

    case choice
    when "1"
      helm_chart = {
        "name" => prompt("Enter deployment name: "),
        "helm_repo_name" => prompt("Enter Helm repository name: "),
        "helm_repo_url" => prompt("Enter Helm repository URL: "),
        "helm_chart_name" => prompt("Enter Helm chart name: ")
      }
      helm_chart["helm_chart_name"] = helm_chart["helm_chart_name"]
      new_config[:deployments][:helm_charts] << helm_chart
    when "2"
      helm_dir = {
        "name" => prompt("Enter deployment name: "),
        "helm_directory" => prompt("Enter path to directory with Chart.yaml: ")
      }
      new_config[:deployments][:helm_dirs] << helm_dir
    when "3"
      manifest = {
        "name" => prompt("Enter deployment name: "),
        "manifest_directory" => prompt("Enter path to directory with manifest files: ")
      }
      new_config[:deployments][:manifests] << manifest
    when "4"
      break
    else
      puts "Invalid choice. Please try again."
    end
  end

  yaml_config = new_config.to_yaml
  puts "Generated Configuration:"
  puts yaml_config

  output_file = prompt("Choose output config path (leave empty for #{CONFIG_FILE}): ")
  if output_file.strip.empty?
    output_file = CONFIG_FILE
  end
  File.write(output_file, yaml_config)
  puts "Configuration saved to #{output_file}"
end

def prompt(message)
  print message
  gets.try(&.strip) || ""
end
