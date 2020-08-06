# coding: utf-8
require "totem"
require "colorize"
require "./types/cnf_conformance_yml_type.cr"
# TODO make constants local or always retrieve from environment variables
# TODO Move constants out

# TODO put this in a module

def final_cnf_results_yml
  results_file = `find ./results/* -name "cnf-conformance-results-*.yml"`.split("\n")[-2].gsub("./", "")
  if results_file.empty?
    raise "No cnf_conformance-results-*.yml found! Did you run the all task?"
  end
  results_file
end

def cnf_config_list(silent=false)
  LOGGING.info("cnf_config_list")
  LOGGING.info("find: find #{CNF_DIR}/* -name #{CONFIG_FILE}")
  cnf_conformance = `find #{CNF_DIR}/* -name "#{CONFIG_FILE}"`.split("\n").select{|x| x.empty? == false}
  LOGGING.info("find response: #{cnf_conformance}")
  if cnf_conformance.size == 0 && !silent
    raise "No cnf_conformance.yml found! Did you run the setup task?"
  end
  cnf_conformance
end

def destination_cnfs_exist?
  cnf_config_list(silent=true).size > 0
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

def wait_for_install(deployment_name, wait_count=180, namespace="default")
  second_count = 0
  all_deployments = `kubectl get deployments --namespace=#{namespace}`
  current_replicas = `kubectl get deployments --namespace=#{namespace} #{deployment_name} -o=jsonpath='{.status.readyReplicas}'`
  LOGGING.info(all_deployments)
  until (current_replicas.empty? != true && current_replicas.to_i > 0) || second_count > wait_count.to_i
    LOGGING.info("second_count = #{second_count}")
    sleep 1
    all_deployments = `kubectl get deployments --namespace=#{namespace}`
    current_replicas = `kubectl get deployments --namespace=#{namespace} #{deployment_name} -o=jsonpath='{.status.readyReplicas}'`
    LOGGING.info(all_deployments)
    second_count = second_count + 1 
  end
end 

def pod_status(pod_name_prefix, field_selector="", namespace="default")
  all_pods = `kubectl get pods #{field_selector} -o jsonpath='{.items[*].metadata.name}'`.split(" ")
  LOGGING.info(all_pods)
  pod = all_pods.find{ | x | x =~ /#{pod_name_prefix}/ }
  status = `kubectl get pods #{pod} -o jsonpath='{.metadata.name},{.status.phase},{.status.containerStatuses[*].ready}'`
  status
end

def node_status(node_name)
  all_nodes = `kubectl get nodes -o jsonpath='{.items[*].metadata.name}'`
  LOGGING.info(all_nodes)
  status = `kubectl get nodes #{node_name} -o jsonpath='{.status.conditions[?(@.type == "Ready")].status}'`
  status
end

def path_has_yml?(config_path)
  if config_path =~ /\.yml/  
    true
  else
    false
  end
end

def config_from_path_or_dir(cnf_path_or_dir)
  if path_has_yml?(cnf_path_or_dir)
    config_file = File.dirname(cnf_path_or_dir)
    config = sample_conformance_yml(config_file)
  else
    config_file = cnf_path_or_dir
    config = sample_conformance_yml(config_file)
  end
  return config
end

def sample_setup_args(sample_dir, args, deploy_with_chart=true, verbose=false, wait_count=180)
  VERBOSE_LOGGING.info "sample_setup_args" if verbose

  config = config_from_path_or_dir(sample_dir)
  config_dir = ensure_cnf_conformance_dir(sample_dir)

  VERBOSE_LOGGING.info "config #{config}" if verbose

  if args.named.keys.includes? "release_name"
    release_name = "#{args.named["release_name"]}"
  else
    release_name = "#{config.get("release_name").as_s?}"
  end
  VERBOSE_LOGGING.info "release_name: #{release_name}" if verbose

  if args.named.keys.includes? "deployment_name"
    deployment_name = "#{args.named["deployment_name"]}"
  else
    deployment_name = "#{config.get("deployment_name").as_s?}" 
  end
  VERBOSE_LOGGING.info "deployment_name: #{deployment_name}" if verbose

  if args.named.keys.includes? "helm_chart"
    helm_chart = "#{args.named["helm_chart"]}"
  else
    helm_chart = "#{config.get("helm_chart").as_s?}" 
  end
  VERBOSE_LOGGING.info "helm_chart: #{helm_chart}" if verbose

  if args.named.keys.includes? "helm_directory"
    helm_directory = "#{args.named["helm_directory"]}"
  else
    helm_directory = "#{config.get("helm_directory").as_s?}" 
  end
  VERBOSE_LOGGING.info "helm_directory: #{helm_directory}" if verbose

  if args.named.keys.includes? "git_clone_url"
    git_clone_url = "#{args.named["git_clone_url"]}"
  else
    git_clone_url = "#{config.get("git_clone_url").as_s?}"
  end
  VERBOSE_LOGGING.info "git_clone_url: #{git_clone_url}" if verbose

  sample_setup(config_file: config_dir, release_name: release_name, deployment_name: deployment_name, helm_chart: helm_chart, helm_directory: helm_directory, git_clone_url: git_clone_url, deploy_with_chart: deploy_with_chart, verbose: verbose, wait_count: wait_count )

end

def ensure_cnf_conformance_yml_path(path)
	LOGGING.info("ensure_cnf_conformance_yml_path")
  if path_has_yml?(path)
    yml = path 
  else
    yml = path + "/cnf-conformance.yml" 
  end
end

def ensure_cnf_conformance_dir(path)
	LOGGING.info("ensure_cnf_conformance_yml_dir")
  if path_has_yml?(path)
    dir = File.dirname(path)
  else
    dir = path
  end
  dir + "/"
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
    # config = get_parsed_cnf_conformance_yml(args)
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
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
  VERBOSE_LOGGING.info "sample_setup" if verbose
  LOGGING.info("config_file #{config_file}")

  current_dir = FileUtils.pwd 
  VERBOSE_LOGGING.info current_dir if verbose 

  destination_cnf_dir = cnf_destination_dir(config_file)

  VERBOSE_LOGGING.info "destination_cnf_dir: #{destination_cnf_dir}" if verbose 
  FileUtils.mkdir_p(destination_cnf_dir) 
  # TODO enable recloning/fetching etc
  # TODO pass in block
  git_clone = `git clone #{git_clone_url} #{destination_cnf_dir}/#{release_name}` if git_clone_url.empty? == false
  VERBOSE_LOGGING.info git_clone if verbose

  # Copy the cnf-conformance.yml
  # Copy the sample 
  # TODO create helm chart directory if it doesn't exist
  # Document this behaviour of the helm chart directory (using it if it exists, 
  # creating it if it doesn't)
  LOGGING.info("File.directory?(#{config_source_dir(config_file)}/#{helm_directory}) #{File.directory?(config_source_dir(config_file) + "/" + helm_directory)}")
  if File.directory?(config_source_dir(config_file) + "/" + helm_directory)
    LOGGING.info("cp -a #{config_source_dir(config_file) + "/" + helm_directory} #{destination_cnf_dir}")
    yml_cp = `cp -a #{config_source_dir(config_file) + "/" + helm_directory} #{destination_cnf_dir}`
    VERBOSE_LOGGING.info yml_cp if verbose
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
      VERBOSE_LOGGING.info "deploying with chart repository" if verbose 
      helm_install = `#{helm} install #{release_name} #{helm_chart}`
      VERBOSE_LOGGING.info helm_install if verbose 

      # Retrieve the helm chart source
      FileUtils.mkdir_p("#{destination_cnf_dir}/#{helm_directory}") 
      helm_pull = `#{helm} pull #{helm_chart}`
      VERBOSE_LOGGING.info helm_pull if verbose 
      # core_mv = `mv #{release_name}-*.tgz #{destination_cnf_dir}/#{helm_directory}`
      # TODO helm_chart should be helm_chart_repo
      VERBOSE_LOGGING.info "mv #{chart_name(helm_chart)}-*.tgz #{destination_cnf_dir}/#{helm_directory}" if verbose
      core_mv = `mv #{chart_name(helm_chart)}-*.tgz #{destination_cnf_dir}/#{helm_directory}`
      VERBOSE_LOGGING.info core_mv if verbose 

      VERBOSE_LOGGING.info "cd #{destination_cnf_dir}/#{helm_directory}; tar -xvf #{destination_cnf_dir}/#{helm_directory}/#{chart_name(helm_chart)}-*.tgz" if verbose
      tar = `cd #{destination_cnf_dir}/#{helm_directory}; tar -xvf #{destination_cnf_dir}/#{helm_directory}/#{chart_name(helm_chart)}-*.tgz`
      VERBOSE_LOGGING.info tar if verbose

      VERBOSE_LOGGING.info "mv #{destination_cnf_dir}/#{helm_directory}/#{chart_name(helm_chart)}/* #{destination_cnf_dir}/#{helm_directory}" if verbose
      move_chart = `mv #{destination_cnf_dir}/#{helm_directory}/#{chart_name(helm_chart)}/* #{destination_cnf_dir}/#{helm_directory}`
      VERBOSE_LOGGING.info move_chart if verbose
    else
      VERBOSE_LOGGING.info "deploying with helm directory" if verbose 
      LOGGING.info("#{helm} install #{release_name} #{destination_cnf_dir}/#{helm_directory}")
      helm_install = `#{helm} install #{release_name} #{destination_cnf_dir}/#{helm_directory}`
      VERBOSE_LOGGING.info helm_install if verbose 
    end

    wait_for_install(deployment_name, wait_count)
    if helm_install.to_s.size > 0 # && helm_pull.to_s.size > 0
      LOGGING.info "Successfully setup #{release_name}".colorize(:green)
    end
  ensure
    cd = `cd #{current_dir}`
    VERBOSE_LOGGING.info cd if verbose 
  end
end

def tools_helm
  current_dir = FileUtils.pwd 
  helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
end

def sample_cleanup(config_file, force=false, verbose=true)
  destination_cnf_dir = cnf_destination_dir(config_file)
  config = parsed_config_file(ensure_cnf_conformance_yml_path(config_file))

  VERBOSE_LOGGING.info "cleanup config: #{config.inspect}" if verbose
  release_name = config.get("release_name").as_s 

  current_dir = FileUtils.pwd 
  helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
  # VERBOSE_LOGGING.debug helm if verbose 
  # destination_cnf_dir = "#{current_dir}/#{CNF_DIR}/#{short_sample_dir(config_path)}"
  dir_exists = File.directory?(destination_cnf_dir)
  ret = true
	LOGGING.info("destination_cnf_dir: #{destination_cnf_dir}")
  if dir_exists || force == true
    rm = `rm -rf #{destination_cnf_dir}`
    VERBOSE_LOGGING.info rm if verbose
    helm_uninstall = `#{helm} uninstall #{release_name}`
    ret = $?.success?
    VERBOSE_LOGGING.info helm_uninstall if verbose
    if ret
      stdout_success "Successfully cleaned up #{release_name}"
    end
  end
  ret
end

def chart_name(helm_chart_repo)
  helm_chart_repo.split("/").last 
end

# TODO: figure out how to check this recursively 
#
# def recursive_json_unmapped(hashy_thing): JSON::Any
#   unmapped_stuff = hashy_thing.json_unmapped

#   Hash(String, String).from_json(hashy_thing.to_json).each_key do |key|
#     if hashy_thing.call(key).responds_to?(:json_unmapped)
#       return unmapped_stuff[key] = recursive_json_unmapped(hashy_thing[key])
#     end
#   end
  
#   unmapped_stuff
# end

# TODO: figure out recursively check for unmapped json and warn on that
# https://github.com/Nicolab/crystal-validator#check
def validate_cnf_conformance_yml(config)
  ccyt_validator = nil
  valid = true 

  begin
    ccyt_validator = CnfConformanceYmlType.from_json(config.settings.to_json)
  rescue ex
    valid = false
    LOGGING.error "✖ ERROR: cnf_conformance.yml field validation error.".colorize(:red)
    LOGGING.error " please check info in the the field name near the text 'CnfConformanceYmlType#' in the error below".colorize(:red)
    LOGGING.error ex.message
    ex.backtrace.each do |x|
      LOGGING.error x
    end
  end

  unmapped_keys_warning_msg = "WARNING: Unmapped cnf_conformance.yml keys. Please add them to the validator".colorize(:yellow)
  unmapped_subkeys_warning_msg = "WARNING: helm_repository is unset or has unmapped subkeys. Please update your cnf_conformance.yml".colorize(:yellow)


  if ccyt_validator && !ccyt_validator.try &.json_unmapped.empty?
    warning_output = [unmapped_keys_warning_msg] of String | Colorize::Object(String)
    warning_output.push(ccyt_validator.try &.json_unmapped.to_s)
    if warning_output.size > 1
      LOGGING.warn warning_output.join("\n")
    end
  end

  #TODO Differentiate between unmapped subkeys or unset top level key.
  if ccyt_validator && !ccyt_validator.try &.helm_repository.try &.json_unmapped.empty? 
    root = {} of String => (Hash(String, JSON::Any) | Nil)
    root["helm_repository"] = ccyt_validator.try &.helm_repository.try &.json_unmapped

    warning_output = [unmapped_subkeys_warning_msg] of String | Colorize::Object(String)
    warning_output.push(root.to_s)
    if warning_output.size > 1
      LOGGING.warn warning_output.join("\n")
    end
  end

  { valid, warning_output }
end
