require "totem"
require "colorize"
# TODO make constants local or always retrieve from environment variables
# TODO Move constants out

# TODO put this in a module

# CONFIG = Totem.from_file "./config.yml"

# TODO return array of cnf directories from the cnfs directory
def cnf_list
end

def cnf_conformance_yml
  cnf_conformance = `find cnfs/* -name "cnf-conformance.yml"`.split("\n")[0]
  if cnf_conformance.empty?
    raise "No cnf_conformance.yml found! Did you run the setup task?"
  end
  Totem.from_file "./#{cnf_conformance}"
end

def cnf_conformance_yml(sample_cnf_destination_dir)
  short_sample_cnf_destination_dir = sample_cnf_destination_dir.split("/")[-1] 
  cnf_conformance = `find #{CNF_DIR}/#{short_sample_cnf_destination_dir}/* -name "cnf-conformance.yml"`.split("\n")[0]
  puts "cnf_conformance: #{cnf_conformance}"
  if cnf_conformance.empty?
    raise "No cnf_conformance.yml found in #{sample_cnf_destination_dir}! Did you run the setup task?"
  end
  Totem.from_file "./#{cnf_conformance}"
end

def get_parsed_cnf_conformance_yml(args)
  puts "get_parsed_cnf_conformance_yml args: #{args.inspect}" if check_verbose(args)
  puts "get_parsed_cnf_conformance_yml args.named.keys: #{args.named.keys.inspect}" if check_verbose(args)
  if args.named.keys.includes? "yml-file" 
    yml_file = args.named["yml-file"].as(String)
  elsif args.named.keys.includes? "cnf-config"
    yml_file = args.named["cnf-config"].as(String)
  else
    yml_file_relative = `find cnfs/* -name "cnf-conformance.yml"`.split("\n")[0]
    if yml_file_relative.empty?
      raise "No cnf_conformance.yml found! Did you run the setup task?"
    end
    yml_file = "./#{yml_file_relative}"
  end
  puts "yml_file: #{yml_file}" if check_verbose(args)
  puts "current directory: #{FileUtils.pwd}" if check_verbose(args)
  Totem.from_file yml_file 
end

def cnf_conformance_yml_file_path(args)
  if args.named.keys.includes? "yml-file"
    yml_file = args.named["yml-file"].as(String)
    # cnf_conformance = File.expand_path(yml_file).split("/")[0..-2].reduce(""){|x,acc| x == "" ? "/" : x + acc + "/"}
    cnf_conformance = File.dirname(yml_file)
  else
    cnf_conformance = `find cnfs/* -name "cnf-conformance.yml"`.split("\n")[0]
    if cnf_conformance.empty?
      raise "No cnf_conformance.yml found! Did you run the setup task?"
    end
  end
  cnf_conformance
end 

def final_cnf_results_yml
  results_file = `find ./* -name "cnf-conformance-results-*.yml"`.split("\n")[-2].gsub("./", "")
  if results_file.empty?
    raise "No cnf_conformance-results-*.yml found! Did you run the all task?"
  end
  results_file
end


def cnf_conformance_dir
  cnf_conformance = `find cnfs/* -name "cnf-conformance.yml"`.split("\n")[0]
  if cnf_conformance.empty?
    raise "No cnf_conformance.yml found! Did you run the setup task?"
  end
  cnf_conformance.split("/")[-2] 
end

def cnf_conformance_dir(source_dir)
  yml_dir = cnf_destination_dir(source_dir) 
  #TODO change into short path
  # source_short_dir = source_dir.split("/")[-1]
  # cnf_conformance = `find cnfs/* -name "#{source_short_dir}"`.split("\n")[0]
  # cnf_conformance = `find cnfs/* -name "#{yml_dir}"`.split("\n")[0]
  # if cnf_conformance.empty?
  #   raise "No directory named #{yml_dir} found! Did you run the setup task?"
  # end
  # cnf_conformance.split("/")[-1] 
  yml_dir.split("/")[-1] 
end

def get_cnf_conformance_dir(args)
  if args.named.keys.includes? "yml-file"
    yml_file = args.named["yml-file"].as(String)
    config = Totem.from_file "#{yml_file}"
    config.get("helm_directory").as_s
  else
    cnf_conformance = `find cnfs/* -name "cnf-conformance.yml"`.split("\n")[0]
    if cnf_conformance.empty?
      raise "No cnf_conformance.yml found! Did you run the setup task?"
    end
    cnf_conformance.split("/")[-2]
  end
end

def parsed_config_file(path)
  if path.empty?
    raise "No cnf_conformance.yml found in #{path}!"
  end
  Totem.from_file "#{path}"
end

def sample_conformance_yml(sample_dir)
  cnf_conformance = `find #{sample_dir}/* -name "cnf-conformance.yml"`.split("\n")[0]
  if cnf_conformance.empty?
    raise "No cnf_conformance.yml found in #{sample_dir}!"
  end
  Totem.from_file "./#{cnf_conformance}"
end

def wait_for_install(deployment_name, wait_count=180)
  second_count = 0
  current_replicas = `kubectl get deployments #{deployment_name} -o=jsonpath='{.status.readyReplicas}'`
  all_deployments = `kubectl get deployments`
  puts all_deployments
  until (current_replicas.empty? != true && current_replicas.to_i > 0) || second_count > wait_count
    puts "second_count = #{second_count}"
    all_deployments = `kubectl get deployments`
    puts all_deployments
    sleep 1
    current_replicas = `kubectl get deployments #{deployment_name} -o=jsonpath='{.status.readyReplicas}'`
    second_count = second_count + 1 
  end
end 

def path_has_yml?(config_path)
  if config_path =~ /\.yml/  
    true
  else
    false
  end
end

def sample_setup_args(sample_dir, args, deploy_with_chart=true, verbose=false, wait_count=180)
  puts "sample_setup_args" if verbose

  if path_has_yml?(sample_dir)
    config_file = File.dirname(sample_dir)
    config = sample_conformance_yml(config_file)
  else
    config_file = sample_dir
    config = sample_conformance_yml(config_file)
  end

  puts "config #{config}" if verbose

  if args.named.keys.includes? "release_name"
    release_name = "#{args.named["release_name"]}"
  else
    release_name = "#{config.get("release_name").as_s?}"
  end
  puts "release_name: #{release_name}" if verbose

  if args.named.keys.includes? "deployment_name"
    deployment_name = "#{args.named["deployment_name"]}"
  else
    deployment_name = "#{config.get("deployment_name").as_s?}" 
  end
  puts "deployment_name: #{deployment_name}" if verbose

  if args.named.keys.includes? "helm_chart"
    helm_chart = "#{args.named["helm_chart"]}"
  else
    helm_chart = "#{config.get("helm_chart").as_s?}" 
  end
  puts "helm_chart: #{helm_chart}" if verbose

  if args.named.keys.includes? "helm_directory"
    helm_directory = "#{args.named["helm_directory"]}"
  else
    helm_directory = "#{config.get("helm_directory").as_s?}" 
  end
  puts "helm_directory: #{helm_directory}" if verbose

  if args.named.keys.includes? "git_clone_url"
    git_clone_url = "#{args.named["git_clone_url"]}"
  else
    git_clone_url = "#{config.get("git_clone_url").as_s?}"
  end
  puts "git_clone_url: #{git_clone_url}" if verbose

  sample_setup(config_file: config_file, release_name: release_name, deployment_name: deployment_name, helm_chart: helm_chart, helm_directory: helm_directory, git_clone_url: git_clone_url, deploy_with_chart: deploy_with_chart, verbose: verbose, wait_count: wait_count )

end

def sample_destination_dir(sample_source_dir)
  current_dir = FileUtils.pwd 
  "#{current_dir}/#{CNF_DIR}/#{short_sample_dir(sample_source_dir)}"
end

def ensure_cnf_conformance_yml_path(config_file)
	LOGGING.info("ensure_cnf_conformance_yml_path")
  if path_has_yml?(config_file)
    yml = config_file
  else
    yml = config_file + "/cnf-conformance.yml" 
  end
end

def cnf_destination_dir(config_file)
	LOGGING.info("cnf_destination_dir")
  if path_has_yml?(config_file)
    yml = config_file
  else
    yml = config_file + "/cnf-conformance.yml" 
  end
  config = parsed_config_file(yml)
  current_dir = FileUtils.pwd 
  deployment_name = "#{config.get("deployment_name").as_s?}" 
	LOGGING.info("deployment_name: #{deployment_name}")
  "#{current_dir}/#{CNF_DIR}/#{deployment_name}"
end

def config_source_dir(config_file)
  if File.directory?(config_file)
    config_file
  else
    File.dirname(config_file)
  end
end

def helm_repo_add(helm_repo_name=nil, helm_repo_url=nil, args : Sam::Args=Sam::Args.new)
  ret = false
  if helm_repo_name == nil || helm_repo_url == nil
    config = get_parsed_cnf_conformance_yml(args)
    current_dir = FileUtils.pwd
    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    helm_repo_name = config.get("helm_repository.name").as_s?
    helm_repo_url = config.get("helm_repository.repo_url").as_s?
  end
  if helm_repo_name && helm_repo_url
    `#{helm} repo add #{helm_repo_name} #{helm_repo_url}`
    if $?.success?
      ret = true
    else
      ret = false
    end
  else
    ret = false
  end
  ret
end

def sample_setup(config_file, release_name, deployment_name, helm_chart, helm_directory, git_clone_url="", deploy_with_chart=true, verbose=false, wait_count=180)
  puts "sample_setup" if verbose
  LOGGING.info("config_file #{config_file}")

  current_dir = FileUtils.pwd 
  puts current_dir if verbose 

  destination_cnf_dir = cnf_destination_dir(config_file)

  puts "destination_cnf_dir: #{destination_cnf_dir}" if verbose 
  FileUtils.mkdir_p(destination_cnf_dir) 
  # TODO enable recloning/fetching etc
  # TODO pass in block
  git_clone = `git clone #{git_clone_url} #{destination_cnf_dir}/#{release_name}` if git_clone_url.empty? == false
  puts git_clone if verbose

  # Copy the cnf-conformance.yml
  # Copy the sample 
  # TODO create helm chart directory if it doesn't exist
  # Document this behaviour of the helm chart directory (using it if it exists, 
  # creating it if it doesn't
  LOGGING.info("File.directory?(#{config_source_dir(config_file)}/#{helm_directory}) #{File.directory?(config_source_dir(config_file) + "/" + helm_directory)}")
  if File.directory?(config_source_dir(config_file) + "/" + helm_directory)
    LOGGING.info("cp -a #{config_source_dir(config_file) + "/" + helm_directory} #{destination_cnf_dir}")
    yml_cp = `cp -a #{config_source_dir(config_file) + "/" + helm_directory} #{destination_cnf_dir}`
    puts yml_cp if verbose
    raise "Copy of #{config_source_dir(config_file) + "/" + helm_directory} to #{destination_cnf_dir} failed!" unless $?.success?
  else
    FileUtils.mkdir_p("#{destination_cnf_dir}/#{helm_directory}") 
  end
  #TODO get yml for the config_file if it doesn't exist
  LOGGING.info("cp -a #{ensure_cnf_conformance_yml_path(config_file)} #{destination_cnf_dir}")
  yml_cp = `cp -a #{ensure_cnf_conformance_yml_path(config_file)} #{destination_cnf_dir}`


  begin

    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    if deploy_with_chart
      puts "deploying with chart repository" if verbose 
      helm_install = `#{helm} install #{release_name} #{helm_chart}`
      puts helm_install if verbose 

      # Retrieve the helm chart source
      FileUtils.mkdir_p("#{destination_cnf_dir}/#{helm_directory}") 
      helm_pull = `#{helm} pull #{helm_chart}`
      puts helm_pull if verbose 
      # core_mv = `mv #{release_name}-*.tgz #{destination_cnf_dir}/#{helm_directory}`
      # TODO helm_chart should be helm_chart_repo
      puts "mv #{chart_name(helm_chart)}-*.tgz #{destination_cnf_dir}/#{helm_directory}" if verbose
      core_mv = `mv #{chart_name(helm_chart)}-*.tgz #{destination_cnf_dir}/#{helm_directory}`
      puts core_mv if verbose 

      puts "cd #{destination_cnf_dir}/#{helm_directory}; tar -xvf #{destination_cnf_dir}/#{helm_directory}/#{chart_name(helm_chart)}-*.tgz" if verbose
      tar = `cd #{destination_cnf_dir}/#{helm_directory}; tar -xvf #{destination_cnf_dir}/#{helm_directory}/#{chart_name(helm_chart)}-*.tgz`
      puts tar if verbose

      puts "mv #{destination_cnf_dir}/#{helm_directory}/#{chart_name(helm_chart)}/* #{destination_cnf_dir}/#{helm_directory}" if verbose
      move_chart = `mv #{destination_cnf_dir}/#{helm_directory}/#{chart_name(helm_chart)}/* #{destination_cnf_dir}/#{helm_directory}`
      puts move_chart if verbose
    else
      puts "deploying with helm directory" if verbose 
      LOGGING.info("#{helm} install #{release_name} #{destination_cnf_dir}/#{helm_directory}")
      helm_install = `#{helm} install #{release_name} #{destination_cnf_dir}/#{helm_directory}`
      puts helm_install if verbose 
    end

    wait_for_install(deployment_name, wait_count)
    if helm_install.to_s.size > 0 # && helm_pull.to_s.size > 0
      puts "Successfully setup #{release_name}".colorize(:green)
    end
  ensure
    cd = `cd #{current_dir}`
    puts cd if verbose 
  end
end

def tools_helm
  current_dir = FileUtils.pwd 
  helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
end

def sample_cleanup(config_file, force=false, verbose=true)
  destination_cnf_dir = cnf_destination_dir(config_file)
  # yml_cp = `cp -a #{ensure_cnf_conformance_yml_path(config_file)} #{destination_cnf_dir}`
  config = parsed_config_file(ensure_cnf_conformance_yml_path(config_file))

  puts "cleanup config: #{config.inspect}" if verbose
  release_name = config.get("release_name").as_s 

  current_dir = FileUtils.pwd 
  helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
  # puts helm if verbose 
  # destination_cnf_dir = "#{current_dir}/#{CNF_DIR}/#{short_sample_dir(config_path)}"
  dir_exists = File.directory?(destination_cnf_dir)
  ret = true
	LOGGING.info("destination_cnf_dir: #{destination_cnf_dir}")
  if dir_exists || force == true
    rm = `rm -rf #{destination_cnf_dir}`
    puts rm if verbose
    helm_uninstall = `#{helm} uninstall #{release_name}`
    ret = $?.success?
    puts helm_uninstall if verbose
    if ret
      puts "Successfully cleaned up #{release_name}".colorize(:green)
    end
  end
  ret
end

def chart_name(helm_chart_repo)
  helm_chart_repo.split("/").last 
end

def short_sample_dir(full_sample_dir)
  full_sample_dir.split("/").last 
end

