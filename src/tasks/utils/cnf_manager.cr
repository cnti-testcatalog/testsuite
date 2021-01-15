# coding: utf-8
require "totem"
require "colorize"
require "./types/cnf_conformance_yml_type.cr"
require "./helm.cr"
require "uuid"

module CNFManager 

  class Config
    def initialize(cnf_config)
      @cnf_config = cnf_config 
    end
    property cnf_config : NamedTuple(destination_cnf_dir: String,
                                     yml_file_path: String,
                                     install_method: Tuple(Symbol, String),
                                     manifest_directory: String,
                                     helm_directory: String, 
                                     helm_chart_path: String, 
                                     manifest_file_path: String, 
                                     git_clone_url: String,
                                     install_script: String,
                                     release_name: String,
                                     service_name:  String,
                                     docker_repository: String,
                                     helm_repository: NamedTuple(name:  String, 
                                                                 repo_url:  String) | Nil,
                                     helm_chart:  String,
                                     helm_chart_container_name: String,
                                     rolling_update_tag: String,
                                     container_names: Array(Hash(String, String )) | Nil,
                                     white_list_container_names: Array(String)) 

    def self.parse_config_yml(config_yml_path : String) : CNFManager::Config
      LOGGING.debug "parse_config_yml config_yml_path: #{config_yml_path}"
      yml_file = CNFManager.ensure_cnf_conformance_yml_path(config_yml_path)
      config = CNFManager.parsed_config_file(yml_file)

      install_method = CNFManager.cnf_installation_method(config)

      CNFManager.generate_and_set_release_name(config_yml_path)

      destination_cnf_dir = CNFManager.cnf_destination_dir(yml_file)

      yml_file_path = CNFManager.ensure_cnf_conformance_dir(config_yml_path)
      manifest_directory = optional_key_as_string(config, "manifest_directory")
      helm_chart = optional_key_as_string(config, "helm_chart")
      release_name = "#{config.get("release_name").as_s?}"
      service_name = optional_key_as_string(config, "service_name")
      helm_directory = optional_key_as_string(config, "helm_directory")
      git_clone_url = optional_key_as_string(config, "git_clone_url")
      install_script = optional_key_as_string(config, "install_script")
      docker_repository = optional_key_as_string(config, "docker_repository")
      if helm_directory.empty?
        working_chart_directory = "exported_chart"
      else
        working_chart_directory = helm_directory
      end
      helm_chart_path = destination_cnf_dir + "/" + working_chart_directory 
      manifest_file_path = destination_cnf_dir + "/" + "temp_template.yml"
      white_list_container_names = config.get("white_list_helm_chart_container_names").as_a.map do |c|
        "#{c.as_s?}"
      end
      container_names_totem = config["container_names"]
      container_names = container_names_totem.as_a.map do |container|
        {"name" => optional_key_as_string(container, "name"),
         "rolling_update_test_tag" => optional_key_as_string(container, "rolling_update_test_tag"),
         "rolling_downgrade_test_tag" => optional_key_as_string(container, "rolling_downgrade_test_tag"),
         "rolling_version_change_test_tag" => optional_key_as_string(container, "rolling_version_change_test_tag"),
         "rollback_from_tag" => optional_key_as_string(container, "rollback_from_tag"),
         }
      end

      # TODO populate nils with entries from cnf-conformance file
      CNFManager::Config.new({ destination_cnf_dir: destination_cnf_dir,
                               yml_file_path: yml_file_path,
                               install_method: install_method,
                               manifest_directory: manifest_directory,
                               helm_directory: helm_directory, 
                               helm_chart_path: helm_chart_path, 
                               manifest_file_path: manifest_file_path,
                               git_clone_url: git_clone_url,
                               install_script: install_script,
                               release_name: release_name,
                               service_name: service_name,
                               docker_repository: docker_repository,
                               helm_repository: {name: "", repo_url: ""},
                               helm_chart: helm_chart,
                               helm_chart_container_name: "",
                               rolling_update_tag: "",
                               container_names: container_names,
                               white_list_container_names: white_list_container_names })

    end
  end

  # Applies a block to each cnf resource
  #
  # `CNFManager.cnf_workload_resources(args, config) {|cnf_config, resource| #your code}
  def self.cnf_workload_resources(args, config, &block)
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    yml_file_path = config.cnf_config[:yml_file_path] 
    # TODO remove helm_directory and use base cnf directory
    helm_directory = config.cnf_config[:helm_directory]
    manifest_directory = config.cnf_config[:manifest_directory] 
    release_name = config.cnf_config[:release_name]
    helm_chart_path = config.cnf_config[:helm_chart_path]
    manifest_file_path = config.cnf_config[:manifest_file_path]
    test_passed = true
    if release_name.empty? # no helm chart
      template_ymls = Helm::Manifest.manifest_ymls_from_file_list(Helm::Manifest.manifest_file_list( destination_cnf_dir + "/" + manifest_directory))
    else
      Helm.generate_manifest_from_templates(release_name, 
                                            helm_chart_path, 
                                            manifest_file_path)
      template_ymls = Helm::Manifest.parse_manifest_as_ymls(manifest_file_path) 
    end
    resource_ymls = Helm.all_workload_resources(template_ymls)
		resource_resp = resource_ymls.map do | resource |
      resp = yield resource 
      LOGGING.debug "cnf_workload_resource yield resp: #{resp}"
      resp
    end
    resource_resp
  end

  #test_passes_completely = workload_resource_test do | cnf_config, resource, container, initialized |
  def self.workload_resource_test(args, config, check_containers = true, &block)
    test_passed = true
    resource_ymls = cnf_workload_resources(args, config) do |resource|
      resource 
    end
    resource_names = Helm.workload_resource_kind_names(resource_ymls)
    LOGGING.info "resource names: #{resource_names}"
    if resource_names && resource_names.size > 0 
      initialized = true
    else
      LOGGING.error "no resource names found"
      initialized = false
    end
		resource_names.each do | resource |
			VERBOSE_LOGGING.debug resource.inspect if check_verbose(args)
      unless resource[:kind].as_s.downcase == "service" ## services have no containers
        containers = KubectlClient::Get.resource_containers(resource[:kind].as_s, resource[:name].as_s)
        if check_containers
        containers.as_a.each do |container|
          resp = yield resource, container, initialized
          LOGGING.debug "yield resp: #{resp}"
          # if any response is false, the test fails
          test_passed = false if resp == false
        end
        else
          resp = yield resource, containers[0], initialized
          LOGGING.debug "yield resp: #{resp}"
          # if any response is false, the test fails
          test_passed = false if resp == false
        end
      end
    end
    LOGGING.debug "workload resource test intialized: #{initialized} test_passed: #{test_passed}"
    initialized && test_passed
  end


  def self.final_cnf_results_yml
    results_file = `find ./results/* -name "cnf-conformance-results-*.yml"`.split("\n")[-2].gsub("./", "")
    if results_file.empty?
      raise "No cnf_conformance-results-*.yml found! Did you run the all task?"
    end
    results_file
  end

  def self.cnf_config_list(silent=false)
    LOGGING.info("cnf_config_list")
    LOGGING.info("find: find #{CNF_DIR}/* -name #{CONFIG_FILE}")
    cnf_conformance = `find #{CNF_DIR}/* -name "#{CONFIG_FILE}"`.split("\n").select{|x| x.empty? == false}
    LOGGING.info("find response: #{cnf_conformance}")
    if cnf_conformance.size == 0 && !silent
      raise "No cnf_conformance.yml found! Did you run the setup task?"
    end
    cnf_conformance
  end

  def self.destination_cnfs_exist?
    cnf_config_list(silent=true).size > 0
  end

  def self.parsed_config_file(path)
    if path.empty?
      raise "No cnf_conformance.yml found in #{path}!"
    end
    Totem.from_file "#{path}"
  end

  def self.sample_conformance_yml(sample_dir)
    cnf_conformance = `find #{sample_dir}/* -name "cnf-conformance.yml"`.split("\n")[0]
    if cnf_conformance.empty?
      raise "No cnf_conformance.yml found in #{sample_dir}!"
    end
    Totem.from_file "./#{cnf_conformance}"
  end

  #TODO move to kubectlclient
  def self.wait_for_install(deployment_name, wait_count : Int32 = 180, namespace="default")
    resource_wait_for_install("deployment", deployment_name, wait_count, namespace)
  end

  #TODO move to kubectlclient
  def self.resource_wait_for_install(kind : String, resource_name : String, wait_count : Int32 = 180, namespace="default")
    # Not all cnfs have #{kind}.  some have only a pod.  need to check if the 
    # passed in pod has a deployment, if so, watch the deployment.  Otherwise watch the pod 
    LOGGING.info "resource_wait_for_install kind: #{kind} resource_name: #{resource_name} namespace: #{namespace}"
    second_count = 0
    all_kind = `kubectl get #{kind} --namespace=#{namespace}`
      LOGGING.debug "all_kind #{all_kind}}"
    # TODO make this work for pods
    case kind.downcase
    when "replicaset", "deployment", "statefulset"
      desired_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.replicas}'`
      LOGGING.debug "desired_replicas #{desired_replicas}"
      current_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.readyReplicas}'`
      LOGGING.debug "current_replicas #{current_replicas}"
    when "daemonset"
      desired_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.desiredNumberScheduled}'`
      LOGGING.debug "desired_replicas #{desired_replicas}"
      current_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.numberAvailable}'`
      LOGGING.debug "current_replicas #{current_replicas}"
    else
      desired_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.replicas}'`
      LOGGING.debug "desired_replicas #{desired_replicas}"
      current_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.readyReplicas}'`
      LOGGING.debug "current_replicas #{current_replicas}"
    end

    until (current_replicas.empty? != true && current_replicas.to_i == desired_replicas.to_i) || second_count > wait_count
      LOGGING.info("second_count = #{second_count}")
      sleep 1
      LOGGING.debug "wait command: kubectl get #{kind} --namespace=#{namespace}"
      all_kind = `kubectl get #{kind} --namespace=#{namespace}`
      case kind.downcase
      when "replicaset", "deployment", "statefulset"
        current_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.readyReplicas}'`
        desired_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.replicas}'`
      when "daemonset"
        current_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.numberAvailable}'`
        desired_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.desiredNumberScheduled}'`
      else
        current_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.readyReplicas}'`
        desired_replicas = `kubectl get #{kind} --namespace=#{namespace} #{resource_name} -o=jsonpath='{.status.replicas}'`
      end
      LOGGING.debug "desired_replicas: #{desired_replicas}"
      LOGGING.info(all_kind)
      second_count = second_count + 1 
    end

    if (current_replicas.empty? != true && current_replicas.to_i == desired_replicas.to_i)
      true
    else
      false
    end
  end

  #TODO move to kubectlclient
  def self.wait_for_install_by_apply(manifest_file, wait_count=180)
    LOGGING.info "wait_for_install_by_apply"
    second_count = 0
    apply_resp = `kubectl apply -f #{manifest_file}`
    LOGGING.info("apply response: #{apply_resp}")
    until (apply_resp =~ /dockercluster.infrastructure.cluster.x-k8s.io\/capd unchanged/) != nil && (apply_resp =~ /cluster.cluster.x-k8s.io\/capd unchanged/) != nil && (apply_resp =~ /kubeadmcontrolplane.controlplane.cluster.x-k8s.io\/capd-control-plane unchanged/) != nil && (apply_resp =~ /kubeadmconfigtemplate.bootstrap.cluster.x-k8s.io\/capd-md-0 unchanged/) !=nil && (apply_resp =~ /machinedeployment.cluster.x-k8s.io\/capd-md-0 unchanged/) != nil && (apply_resp =~ /machinehealthcheck.cluster.x-k8s.io\/capd-mhc-0 unchanged/) != nil || second_count > wait_count.to_i
      LOGGING.info("second_count = #{second_count}")
      sleep 1
      apply_resp = `kubectl apply -f #{manifest_file}`
      LOGGING.info("apply response: #{apply_resp}")
      second_count = second_count + 1 
    end
  end 



  #TODO move to kubectlclient
  def self.pod_status(pod_name_prefix, field_selector="", namespace="default")
    all_pods = `kubectl get pods #{field_selector} -o jsonpath='{.items[*].metadata.name},{.items[*].metadata.creationTimestamp}'`.split(",")

    LOGGING.info(all_pods)
    all_pod_names = all_pods[0].split(" ")
    time_stamps = all_pods[1].split(" ")
    pods_times = all_pod_names.map_with_index do |name, i|
      {:name => name, :time => time_stamps[i]}
    end
    LOGGING.info("pods_times: #{pods_times}")

    # puts "Name: #{all_pods[0]}"
    # puts "Time Stamp: #{all_pods[1]}"
    latest_pod_time = pods_times.reduce() do | acc, i |
      # if current i > acc
      LOGGING.info("ACC: #{acc}")
      LOGGING.info("I:#{i}")
      LOGGING.info("pod_name_prefix: #{pod_name_prefix}")
      if (acc[:name] =~ /#{pod_name_prefix}/).nil?
        acc = {:name => "not found", :time => "not_found"} 
      end
      if i[:name] =~ /#{pod_name_prefix}/
        acc = i
        if acc == ""
          existing_time = Time.parse!( "#{i[:time]} +00:00", "%Y-%m-%dT%H:%M:%SZ %z")
        else
          existing_time = Time.parse!( "#{acc[:time]} +00:00", "%Y-%m-%dT%H:%M:%SZ %z")
        end
        new_time = Time.parse!( "#{i[:time]} +00:00", "%Y-%m-%dT%H:%M:%SZ %z")
        if new_time <= existing_time
          acc = i
        else
          acc
        end
      else
        acc
      end
    end
    LOGGING.info("latest_pod_time: #{latest_pod_time}")

    pod = latest_pod_time[:name].not_nil!
    # pod = all_pod_names[time_stamps.index(latest_time).not_nil!]
    # pod = all_pods.select{ | x | x =~ /#{pod_name_prefix}/ }
    puts "Pods Found: #{pod}"
    status = `kubectl get pods #{pod} -o jsonpath='{.metadata.name},{.status.phase},{.status.containerStatuses[*].ready}'`
    status
  end

  #TODO move to kubectlclient
  def self.node_status(node_name)
    all_nodes = `kubectl get nodes -o jsonpath='{.items[*].metadata.name}'`
    LOGGING.info(all_nodes)
    status = `kubectl get nodes #{node_name} -o jsonpath='{.status.conditions[?(@.type == "Ready")].status}'`
    status
  end

  def self.path_has_yml?(config_path)
    if config_path =~ /\.yml/  
      true
    else
      false
    end
  end

  def self.config_from_path_or_dir(cnf_path_or_dir)
    if path_has_yml?(cnf_path_or_dir)
      config_file = File.dirname(cnf_path_or_dir)
      config = sample_conformance_yml(config_file)
    else
      config_file = cnf_path_or_dir
      config = sample_conformance_yml(config_file)
    end
    return config
  end

  def self.ensure_cnf_conformance_yml_path(path : String)
    LOGGING.info("ensure_cnf_conformance_yml_path")
    if path_has_yml?(path)
      yml = path 
    else
      yml = path + "/cnf-conformance.yml" 
    end
  end

  def self.ensure_cnf_conformance_dir(path)
    LOGGING.info("ensure_cnf_conformance_yml_dir")
    if path_has_yml?(path)
      dir = File.dirname(path)
    else
      dir = path
    end
    dir + "/"
  end

  #TODO check in yml file for release_name, if none, generate name
  def self.release_name?(config)
    release_name = optional_key_as_string(config, "release_name").split(" ")[0]
    if release_name.empty?
      false
    else
      true
    end
  end

  def self.exclusive_install_method_tags?(config)
    installation_type_count = ["helm_chart", "helm_directory", "manifest_directory"].reduce(0) do |acc, install_type|
      begin
        test_tag = config[install_type]
        LOGGING.debug "install type count install_type: #{install_type}"
        if install_type.empty?
          acc
        else
          acc = acc + 1
        end
      rescue ex
        LOGGING.debug "install_type: #{install_type} not found in #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}"
        # LOGGING.debug ex.message
        # ex.backtrace.each do |x|
        #   LOGGING.debug x
        # end
        acc
      end
    end
    LOGGING.debug "installation_type_count: #{installation_type_count}"
    if installation_type_count > 1
      false
    else
      true
    end
  end

  #TODO Determine, for cnf, whether a helm chart, helm directory, or manifest directory is being used for installation
  def self.cnf_installation_method(config)
    LOGGING.info "cnf_installation_method"
    LOGGING.info "cnf_installation_method config: #{config}"
    LOGGING.info "cnf_installation_method config: #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}"
    helm_chart = optional_key_as_string(config, "helm_chart")
    helm_directory = optional_key_as_string(config, "helm_directory")
    manifest_directory = optional_key_as_string(config, "manifest_directory")

    unless CNFManager.exclusive_install_method_tags?(config)
      puts "Error: Must populate at lease one installation type in #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}: choose either helm_chart, helm_directory, or manifest_directory in cnf-conformance.yml!".colorize(:red)
      raise "Error: Must populate at lease one installation type in #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}: choose either helm_chart, helm_directory, or manifest_directory in cnf-conformance.yml!"
    end
    if !helm_chart.empty?
      {:helm_chart, helm_chart}
    elsif !helm_directory.empty?
      {:helm_directory, helm_directory}
    elsif !manifest_directory.empty?
      {:manifest_directory, manifest_directory}
    else
      puts "Error: Must populate at lease one installation type in #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}: choose either helm_chart, helm_directory, or manifest_directory.".colorize(:red)
      raise "Error in cnf-conformance.yml!"
    end
  end

  def self.helm_template_header(helm_chart_or_directory, template_file="/tmp/temp_template.yml")
    LOGGING.info "helm_template_header"
    helm = CNFSingleton.helm
    # generate helm chart release name
    # use --dry-run to generate yml file
    LOGGING.info("#{helm} install --dry-run --generate-name #{helm_chart_or_directory} > #{template_file}")
    helm_install = `#{helm} install --dry-run --generate-name #{helm_chart_or_directory} > #{template_file}`
    raw_template = File.read(template_file)
    split_template = raw_template.split("---")
    template_header = split_template[0]
    parsed_template_header = YAML.parse(template_header)
  end

  def self.helm_chart_template_release_name(helm_chart_or_directory, template_file="/tmp/temp_template.yml")
    LOGGING.info "helm_chart_template_release_name"
    hth = helm_template_header(helm_chart_or_directory, template_file)
    LOGGING.debug "helm template: #{hth}"
    hth["NAME"]
  end

  def self.generate_and_set_release_name(config_yml_path)
    LOGGING.info "generate_and_set_release_name"
    yml_file = CNFManager.ensure_cnf_conformance_yml_path(config_yml_path)
    config = CNFManager.parsed_config_file(yml_file)

    predefined_release_name = optional_key_as_string(config, "release_name")
    LOGGING.debug "predefined_release_name: #{predefined_release_name}"
    if predefined_release_name.empty?
      install_method = self.cnf_installation_method(config)
      LOGGING.debug "install_method: #{install_method}"
      case install_method[0]
      when :helm_chart
        LOGGING.debug "helm_chart install method: #{install_method[1]}"
        release_name = helm_chart_template_release_name(install_method[1])
      when :helm_directory
        LOGGING.debug "helm_directory install method: #{yml_file}/#{install_method[1]}"
        release_name = helm_chart_template_release_name("#{yml_file}/#{install_method[1]}")
      when :manifest_directory
        LOGGING.debug "manifest_directory install method"
        release_name = UUID.random.to_s
      else 
        raise "Install method should be either helm_chart, helm_directory, or manifest_directory"
      end
      #TODO set generated helm chart release name in yml file
      LOGGING.debug "generate_and_set_release_name: #{release_name}"
      update_yml(yml_file, "release_name", release_name)
    end
  end


  def self.cnf_destination_dir(config_file)
    LOGGING.info("cnf_destination_dir config_file: #{config_file}")
    if path_has_yml?(config_file)
      yml = config_file
    else
      yml = config_file + "/cnf-conformance.yml" 
    end
    config = parsed_config_file(yml)
    LOGGING.info "cnf_destination_dir parsed_config_file config: #{config}"
    current_dir = FileUtils.pwd 
    release_name = optional_key_as_string(config, "release_name").split(" ")[0]
    LOGGING.info "release_name: #{release_name}"
    LOGGING.info "cnf destination dir: #{current_dir}/#{CNF_DIR}/#{release_name}"
    "#{current_dir}/#{CNF_DIR}/#{release_name}"
  end

  def self.config_source_dir(config_file)
    if File.directory?(config_file)
      config_file
    else
      File.dirname(config_file)
    end
  end

  #TODO extract this and put into the helm module
  def self.helm_repo_add(helm_repo_name=nil, helm_repo_url=nil, args : Sam::Args=Sam::Args.new)
    LOGGING.info "helm_repo_add repo_name: #{helm_repo_name} repo_url: #{helm_repo_url} args: #{args.inspect}"
    ret = false
    if helm_repo_name == nil || helm_repo_url == nil
      # config = get_parsed_cnf_conformance_yml(args)
      config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
      LOGGING.info "helm path: #{CNFSingleton.helm}"
      # current_dir = FileUtils.pwd
      # #helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
      helm = CNFSingleton.helm
      helm_repo_name = config.get("helm_repository.name").as_s?
      LOGGING.info "helm_repo_name: #{helm_repo_name}"
      helm_repo_url = config.get("helm_repository.repo_url").as_s?
      LOGGING.info "helm_repo_url: #{helm_repo_url}"
    end
    if helm_repo_name && helm_repo_url
      LOGGING.info "helm  repo add command: #{helm} repo add #{helm_repo_name} #{helm_repo_url}"
      # helm_resp = `#{helm} repo add #{helm_repo_name} #{helm_repo_url}`
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
        LOGGING.error "helm repo add command critically failed: #{helm} repo add #{helm_repo_name} #{helm_repo_url}"
      end
      # Helm version v3.3.3 gave us a surprise
      if helm_resp =~ /has been added|already exists/ || error =~ /has been added|already exists/
      # if $?.success?
        ret = true
      else
        ret = false
      end
    else
      ret = false
    end
    ret
  end

  #TODO extract this and put into the helm module
  def self.helm_gives_k8s_warning?(verbose=false)
    helm = CNFSingleton.helm
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


  # #TODO replace with the CNFManager::Config named tuple functionality
  # def self.sample_setup_args(sample_dir, args, deploy_with_chart=true, verbose=false, wait_count=180, install_from_manifest=false)
  #   VERBOSE_LOGGING.info "sample_setup_args" if verbose
  #
  #   config = config_from_path_or_dir(sample_dir)
  #   config_dir = ensure_cnf_conformance_dir(sample_dir)
  #   LOGGING.info "sample_setup_args config for #{config.config_paths[0]}/#{config.config_name}.#{config.config_type}"
  #
  #   VERBOSE_LOGGING.info "config #{config}" if verbose
  #
  #   if args.named.keys.includes? "release_name"
  #     release_name = "#{args.named["release_name"]}"
  #   else
  #     release_name = "#{config.get("release_name").as_s?}"
  #   end
  #   VERBOSE_LOGGING.info "release_name: #{release_name}" if verbose
  #
  #   if args.named.keys.includes? "deployment_name"
  #     deployment_name = "#{args.named["deployment_name"]}"
  #   else
  #     deployment_name = optional_key_as_string(config, "deployment_name")
  #   end
  #   VERBOSE_LOGGING.info "deployment_name: #{deployment_name}" if verbose
  #
  #   if args.named.keys.includes? "helm_chart"
  #     helm_chart = "#{args.named["helm_chart"]}"
  #   else
  #     helm_chart = optional_key_as_string(config, "helm_chart")
  #   end
  #   VERBOSE_LOGGING.info "helm_chart: #{helm_chart}" if verbose
  #
  #   if args.named.keys.includes? "helm_directory"
  #     helm_directory = "#{args.named["helm_directory"]}"
  #   else
  #     helm_directory = optional_key_as_string(config, "helm_directory")
  #   end
  #   VERBOSE_LOGGING.info "helm_directory: #{helm_directory}" if verbose
  #
  #   if args.named.keys.includes? "manifest_directory"
  #     manifest_directory = "#{args.named["manifest_directory"]}"
  #   else
  #     manifest_directory = optional_key_as_string(config, "manifest_directory")
  #   end
  #   VERBOSE_LOGGING.info "manifest_directory: #{manifest_directory}" if verbose
  #
  #   if args.named.keys.includes? "git_clone_url"
  #     git_clone_url = "#{args.named["git_clone_url"]}"
  #   else
  #     git_clone_url = "#{config.get("git_clone_url").as_s?}"
  #   end
  #   VERBOSE_LOGGING.info "git_clone_url: #{git_clone_url}" if verbose
  #
  #   sample_setup(config_file: config_dir, release_name: release_name, deployment_name: deployment_name, helm_chart: helm_chart, helm_directory: helm_directory, git_clone_url: git_clone_url, deploy_with_chart: deploy_with_chart, verbose: verbose, wait_count: wait_count, manifest_directory: manifest_directory, install_from_manifest: install_from_manifest )
  #
  # end

  def self.sample_setup_cli_args(args)
    VERBOSE_LOGGING.info "sample_setup_cli_args" if check_verbose(args)
    VERBOSE_LOGGING.debug "args = #{args.inspect}" if check_verbose(args)
    if args.named.keys.includes? "cnf-config"
      yml_file = args.named["cnf-config"].as(String)
      cnf_path = File.dirname(yml_file)
    elsif args.named.keys.includes? "cnf-path"
      cnf_path = args.named["cnf-path"].as(String)
    else
      stdout_failure "Error: You must supply either cnf-config or cnf-path"
      exit 1
    end
    if args.named.keys.includes? "wait_count"
      wait_count = args.named["wait_count"].to_i
    elsif args.named.keys.includes? "wait-count"
      wait_count = args.named["wait-count"].to_i
    else
      wait_count = 180
    end
    {config_file: cnf_path, wait_count: wait_count, verbose: check_verbose(args)}
  end

  #TODO replace with the CNFManager::Config named tuple functionality
  #sample_setup({config_file: cnf_path, wait_count: wait_count})
  def self.sample_setup(cli_args) 
    config_file = cli_args[:config_file]
    wait_count = cli_args[:wait_count]
    verbose = cli_args[:verbose]
    config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_conformance_yml_path(config_file))    
    release_name = config.cnf_config[:release_name]
    install_method = config.cnf_config[:install_method]

  #   sample_setup(config_file: config_file, release_name: "", deployment_name: "", helm_chart: "", helm_directory: "", verbose: verbose, wait_count: wait_count)
  # end
  #
  # def self.sample_setup(config_file, release_name, deployment_name, helm_chart, helm_directory, manifest_directory = "", git_clone_url="", deploy_with_chart=true, verbose=false, wait_count=180, install_from_manifest=false)


    #TODO add helm arguments to the cnf-conformance yml
    VERBOSE_LOGGING.info "sample_setup" if verbose
    LOGGING.info("config_file #{config_file}")

    current_dir = FileUtils.pwd 
    VERBOSE_LOGGING.info current_dir if verbose 

    config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_conformance_yml_path(config_file))    
    LOGGING.debug "config in sample_setup: #{config.cnf_config}"

    release_name = config.cnf_config[:release_name]
    install_method = config.cnf_config[:install_method]
    helm_directory = config.cnf_config[:helm_directory]
    manifest_directory = config.cnf_config[:manifest_directory]
    git_clone_url = config.cnf_config[:git_clone_url]

    # if install_method[0] == :helm_directory
    #   deploy_with_chart = false
    # end 
    helm_chart = config.cnf_config[:helm_chart]
    helm_chart_path = config.cnf_config[:helm_chart_path]
    LOGGING.debug "helm_directory: #{helm_directory}"

    #TODO move to sandbox module
    # generate_and_set_release_name(config)
    destination_cnf_dir = CNFManager.cnf_destination_dir(config_file)

    VERBOSE_LOGGING.info "destination_cnf_dir: #{destination_cnf_dir}" if verbose 
    LOGGING.debug "mkdir_p destination_cnf_dir: #{destination_cnf_dir}"
    FileUtils.mkdir_p(destination_cnf_dir) 

    # TODO enable recloning/fetching etc
    # TODO pass in block
    git_clone = `git clone #{git_clone_url} #{destination_cnf_dir}/#{release_name}`  if git_clone_url.empty? == false
    VERBOSE_LOGGING.info git_clone if verbose

    # Create a unique directory for the cnf that is to be installed under ./cnfs
    # Only copy the cnf's cnf-conformance.yml and it's helm_directory or manifest directory (if it exists)

    # Use manifest directory if helm directory empty
    #TODO move to sandbox module
    # TODO make an 'install from' function that returns {:helm_chart (etc), <install from string>}
    if install_method[0] == :manifest_directory
      manifest_or_helm_directory = config_source_dir(config_file) + "/" + manifest_directory 
    elsif !helm_directory.empty?
      manifest_or_helm_directory = config_source_dir(config_file) + "/" + helm_directory 
    else
      # this is not going to exist
      manifest_or_helm_directory = helm_chart_path #./cnfs/<cnf-release-name>/exported_chart
    end
      
    LOGGING.info("File.directory?(#{manifest_or_helm_directory}) #{File.directory?(manifest_or_helm_directory)}")
    # if the helm directory already exists, copy helm_directory contents into cnfs/<cnf-name>/<helm-directory-of-the-same-name>
    if !manifest_or_helm_directory.empty? && manifest_or_helm_directory =~ /exported_chart/ 
      LOGGING.info "Ensuring exported helm directory is created"
      LOGGING.debug "mkdir_p destination_cnf_dir/exported_chart: #{manifest_or_helm_directory}"
      FileUtils.mkdir_p("#{manifest_or_helm_directory}") 
    elsif !manifest_or_helm_directory.empty? && File.directory?(manifest_or_helm_directory) 
      # if !manifest_or_helm_directory.empty? && File.directory?(manifest_or_helm_directory) 
      LOGGING.info "Ensuring helm directory is copied"
      LOGGING.info("cp -a #{manifest_or_helm_directory} #{destination_cnf_dir}")
      yml_cp = `cp -a #{manifest_or_helm_directory} #{destination_cnf_dir}`
      VERBOSE_LOGGING.info yml_cp if verbose
      raise "Copy of #{manifest_or_helm_directory} to #{destination_cnf_dir} failed!" unless $?.success?
      # else
      #   LOGGING.info "Ensuring exported helm directory is created"
      #   LOGGING.debug "mkdir_p destination_cnf_dir/exported_chart: #{manifest_or_helm_directory}"
      #   FileUtils.mkdir_p("#{manifest_or_helm_directory}") 
    end

    #TODO move to sandbox module
    LOGGING.info "copy cnf-conformance.yml file"
    LOGGING.info("cp -a #{ensure_cnf_conformance_yml_path(config_file)} #{destination_cnf_dir}")
    yml_cp = `cp -a #{ensure_cnf_conformance_yml_path(config_file)} #{destination_cnf_dir}`

    begin

      helm = CNFSingleton.helm
      LOGGING.info "helm path: #{CNFSingleton.helm}"

      if install_method[0] == :manifest_directory
        VERBOSE_LOGGING.info "deploying by manifest file" if verbose 
        #kubectl apply -f ./sample-cnfs/k8s-non-helm/manifests 
        LOGGING.info("kubectl apply -f #{destination_cnf_dir}/#{manifest_directory}")
        manifest_install = `kubectl apply -f #{destination_cnf_dir}/#{manifest_directory}`
        VERBOSE_LOGGING.info manifest_install if verbose 

      elsif install_method[0] == :helm_chart
        VERBOSE_LOGGING.info "deploying with chart repository" if verbose 
        LOGGING.info "helm command: #{helm} install #{release_name} #{helm_chart}"
        helm_install = `#{helm} install #{release_name} #{helm_chart}`
        VERBOSE_LOGGING.info helm_install if verbose 

        # Retrieve the helm chart source
        #TODO move to sandbox module
        LOGGING.debug "mkdir_p destination_cnf_dir/helm_directory: #{destination_cnf_dir}/#{helm_directory}"
        FileUtils.mkdir_p("#{destination_cnf_dir}/#{helm_directory}") 
        LOGGING.debug "helm command pull: #{helm} pull #{helm_chart}"
        helm_pull = `#{helm} pull #{helm_chart}`
        VERBOSE_LOGGING.info helm_pull if verbose 
        # core_mv = `mv #{release_name}-*.tgz #{destination_cnf_dir}/#{helm_directory}`
        # TODO helm_chart should be helm_chart_repo
        # TODO make this into a tar chart function
        # VERBOSE_LOGGING.info "mv #{chart_name(helm_chart)}-*.tgz #{destination_cnf_dir}/#{helm_directory}" if verbose
        # core_mv = `mv #{chart_name(helm_chart)}-*.tgz #{destination_cnf_dir}/#{helm_directory}`
        VERBOSE_LOGGING.info "mv #{chart_name(helm_chart)}-*.tgz #{destination_cnf_dir}/exported_chart" if verbose
        core_mv = `mv #{chart_name(helm_chart)}-*.tgz #{destination_cnf_dir}/exported_chart`
        VERBOSE_LOGGING.info core_mv if verbose 

        # VERBOSE_LOGGING.info "cd #{destination_cnf_dir}/#{helm_directory}; tar -xvf #{destination_cnf_dir}/#{helm_directory}/#{chart_name(helm_chart)}-*.tgz" if verbose
        # tar = `cd #{destination_cnf_dir}/#{helm_directory}; tar -xvf #{destination_cnf_dir}/#{helm_directory}/#{chart_name(helm_chart)}-*.tgz`
        VERBOSE_LOGGING.info "cd #{destination_cnf_dir}/exported_chart; tar -xvf #{destination_cnf_dir}/exported_chart/#{chart_name(helm_chart)}-*.tgz" if verbose
        tar = `cd #{destination_cnf_dir}/exported_chart; tar -xvf #{destination_cnf_dir}/exported_chart/#{chart_name(helm_chart)}-*.tgz`
        VERBOSE_LOGGING.info tar if verbose

        # VERBOSE_LOGGING.info "mv #{destination_cnf_dir}/#{helm_directory}/#{chart_name(helm_chart)}/* #{destination_cnf_dir}/#{helm_directory}" if verbose
        # move_chart = `mv #{destination_cnf_dir}/#{helm_directory}/#{chart_name(helm_chart)}/* #{destination_cnf_dir}/#{helm_directory}`
        VERBOSE_LOGGING.info "mv #{destination_cnf_dir}/exported_chart/#{chart_name(helm_chart)}/* #{destination_cnf_dir}/exported_chart" if verbose
        move_chart = `mv #{destination_cnf_dir}/exported_chart/#{chart_name(helm_chart)}/* #{destination_cnf_dir}/exported_chart`
        VERBOSE_LOGGING.info move_chart if verbose
      elsif install_method[0] == :helm_directory
        VERBOSE_LOGGING.info "deploying with helm directory" if verbose 
        #TODO Add helm options into cnf-conformance yml
        #e.g. helm install nsm --set insecure=true ./nsm/helm_chart
        LOGGING.info("#{helm} install #{release_name} #{destination_cnf_dir}/#{helm_directory}")
        helm_install = `#{helm} install #{release_name} #{destination_cnf_dir}/#{helm_directory}`
        VERBOSE_LOGGING.info helm_install if verbose 
      else
        raise "Deployment method not found"
      end

      #TODO change deployment_name to resource name
      #TODO loop through all resources and wait for all resources to install
      resource_ymls = cnf_workload_resources(nil, config) do |resource|
        resource 
      end
      resource_names = Helm.workload_resource_kind_names(resource_ymls)
      resource_names.each do | resource |
        case resource[:kind].as_s.downcase 
        when "replicaset", "deployment", "statefulset", "pod", "daemonset"
        # wait_for_install(resource_name, wait_count)
          resource_wait_for_install(resource[:kind].as_s, resource[:name].as_s, wait_count)
        end
      end
      if helm_install.to_s.size > 0 # && helm_pull.to_s.size > 0
        LOGGING.info "Successfully setup #{release_name}".colorize(:green)
      end
    ensure
      cd = `cd #{current_dir}`
      VERBOSE_LOGGING.info cd if verbose 
    end
  end

  # TODO move to helm module
  def self.local_helm_path
    current_dir = FileUtils.pwd 
    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
  end

  def self.sample_cleanup(config_file, force=false, installed_from_manifest=false, verbose=true)
    LOGGING.info "sample_cleanup"
    destination_cnf_dir = CNFManager.cnf_destination_dir(config_file)
    config = parsed_config_file(ensure_cnf_conformance_yml_path(config_file))

    VERBOSE_LOGGING.info "cleanup config: #{config.inspect}" if verbose
    release_name = "#{config.get("release_name").as_s?}"
    manifest_directory = destination_cnf_dir + "/" + "#{config["manifest_directory"]? && config["manifest_directory"].as_s?}"

    LOGGING.info "helm path: #{CNFSingleton.helm}"
    helm = CNFSingleton.helm
    dir_exists = File.directory?(destination_cnf_dir)
    ret = true
    LOGGING.info("destination_cnf_dir: #{destination_cnf_dir}")
    if dir_exists || force == true
      if installed_from_manifest
        LOGGING.info "kubectl delete command: kubectl delete -f #{manifest_directory}"
        kubectl_delete = `kubectl delete -f #{manifest_directory}`
        ret = $?.success?
        VERBOSE_LOGGING.info kubectl_delete if verbose
        rm = `rm -rf #{destination_cnf_dir}`
        VERBOSE_LOGGING.info rm if verbose
        if ret
          stdout_success "Successfully cleaned up #{manifest_directory} directory"
        end
      else
        LOGGING.info "helm uninstall command: #{helm} uninstall #{release_name.split(" ")[0]}"
        #TODO add capability to add helm options for uninstall
        helm_uninstall = `#{helm} uninstall #{release_name.split(" ")[0]}`
        ret = $?.success?
        VERBOSE_LOGGING.info helm_uninstall if verbose
        rm = `rm -rf #{destination_cnf_dir}`
        VERBOSE_LOGGING.info rm if verbose
        if ret
          stdout_success "Successfully cleaned up #{release_name.split(" ")[0]}"
        end
      end
    end
    ret
  end

  # TODO move to helm module
  def self.chart_name(helm_chart_repo)
    helm_chart_repo.split("/").last 
  end

  # TODO: figure out how to check this recursively 
  #
  # def self.recursive_json_unmapped(hashy_thing): JSON::Any
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
  def self.validate_cnf_conformance_yml(config)
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

end
