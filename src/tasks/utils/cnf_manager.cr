# coding: utf-8
require "totem"
require "colorize"
require "helm"
require "git"
require "uuid"
require "./points.cr"
require "./task.cr"
require "./jaeger.cr"
require "tar"
require "./oran_monitor.cr"
require "./cnf_installation/install_common.cr"
require "./cnf_installation/manifest.cr"
require "log"
require "ecr"

module CNFManager
  class ElapsedTimeConfigMapTemplate
    # elapsed_time should be Int32 but it is being passed as string
    # So the old behaviour has been retained as is to prevent any breakages
    def initialize(@release_name : String, @helm_used : Bool, @elapsed_time : String, @immutable : Bool, @tracing_used : Bool, @e2_found : Bool)
    end

    ECR.def_to_s("src/templates/elapsed_time_configmap.yml.ecr")
  end

  def self.cnf_resource_ymls(args, config)
    Log.info { "cnf_resource_ymls" }
    manifest_ymls = CNFInstall::Manifest.manifest_path_to_ymls(COMMON_MANIFEST_FILE_PATH)

    manifest_ymls = manifest_ymls.reject! {|x|
      # reject resources that contain the 'helm.sh/hook: test' annotation
      x.dig?("metadata","annotations","helm.sh/hook")
    }
    Log.debug { "cnf_resource_ymls: #{manifest_ymls}" }
    manifest_ymls 
  end

  def self.cnf_resources(args, config, &block)
    manifest_ymls = cnf_resource_ymls(args, config)
    resource_resp = manifest_ymls.map do | resource |
      resp = yield resource
      Log.debug { "cnf_workload_resource yield resp: #{resp}" }
      resp
    end
    resource_resp
  end

  #TODO define cnf_resources
  # add all code from cnf_workload resources and the reject from the helm.workload_resource_by_kind
  # (removes helm test annotations)
  # return all the resources
  # make cnf_workload_resources call cnf_resoures with a block that calls the extra filter (all_workload_resources)

  # Applies a block to each cnf resource
  #
  # ```
  # CNFManager.cnf_workload_resources(args, config) {|cnf_config, resource| #your code}
  # ```
  
  def self.get_deployment_namespace(config)
    install_method = config.dynamic.install_method
    case install_method[0]
    when CNFInstall::InstallMethod::HelmChart, CNFInstall::InstallMethod::HelmDirectory
      config_namespace = config.deployments.get_deployment_param(:namespace)
      if !config_namespace.empty?
        Log.info { "deployment namespace was set to: #{config_namespace}" }
        config_namespace
      else
        Log.info { "deployment namespace was set to: #{DEFAULT_CNF_NAMESPACE}" }
        DEFAULT_CNF_NAMESPACE
      end
    else
      Log.info { "deployment namespace was set to: default" }
      "default"
    end
  end


  def self.cnf_workload_resources(args, config, &block)
    deployment_namespace = CNFManager.get_deployment_namespace(config)
    manifest_ymls = cnf_resource_ymls(args, config)
    # call cnf cnf_resources to get unfiltered yml
    resource_ymls = Helm.all_workload_resources(manifest_ymls, deployment_namespace)
    resource_resp = resource_ymls.map do | resource |
      resp = yield resource
      Log.debug { "cnf_workload_resource yield resp: #{resp}" }
      resp
    end

    resource_resp
  end

  #test_passes_completely = workload_resource_test do | cnf_config, resource, container, initialized |
  def self.workload_resource_test(args, config,
                                  check_containers = true,
                                  check_service = false,
                                  &block  : (NamedTuple(kind: String, name: String, namespace: String),
                                             JSON::Any, JSON::Any, Bool | Nil) -> Bool | Nil)
            # resp = yield resource, container, volumes, initialized
    test_passed = true
    resource_ymls = cnf_workload_resources(args, config) do |resource|
      resource
    end
    deployment_namespace = CNFManager.get_deployment_namespace(config)
    resource_names = Helm.workload_resource_kind_names(resource_ymls, default_namespace: deployment_namespace)
    Log.info { "resource names: #{resource_names}" }
    if resource_names && resource_names.size > 0
      initialized = true
    else
      Log.error { "no resource names found" }
      initialized = false
    end
    # todo check to see if following 'resource' variable is conflicting with above resource variable
		resource_names.each do | resource |
			Log.for("verbose").debug { resource.inspect } if check_verbose(args)
      volumes = KubectlClient::Get.resource_volumes(kind: resource[:kind], resource_name: resource[:name], namespace: resource[:namespace])
      Log.for("verbose").debug { "check_service: #{check_service}" } if check_verbose(args)
      Log.for("verbose").debug { "check_containers: #{check_containers}" } if check_verbose(args)
      case resource[:kind].downcase
      when "service"
        if check_service
          Log.info { "checking service: #{resource}" }
          resp = yield resource, JSON.parse(%([{}])), volumes, initialized
          Log.debug { "yield resp: #{resp}" }
          # if any response is false, the test fails
          test_passed = false if resp == false
        end
      else
        containers = KubectlClient::Get.resource_containers(resource[:kind], resource[:name], resource[:namespace])
				if check_containers
					containers.as_a.each do |container|
						resp = yield resource, container, volumes, initialized
						Log.debug { "yield resp: #{resp}" }
						# if any response is false, the test fails
						test_passed = false if resp == false
					end
				else
					resp = yield resource, containers, volumes, initialized
					Log.debug { "yield resp: #{resp}" }
					# if any response is false, the test fails
					test_passed = false if resp == false
				end
      end
		end
    Log.debug { "workload resource test intialized: #{initialized} test_passed: #{test_passed}" }
    initialized && test_passed
  end

  def self.cnf_config_list(silent=false)
    Log.info { "cnf_config_list" }
    find_cmd = "find #{CNF_DIR}/* -name \"#{CONFIG_FILE}\""
    Log.info { "find: #{find_cmd}" }
    Process.run(
      find_cmd,
      shell: true,
      output: find_stdout = IO::Memory.new,
      error: find_stderr = IO::Memory.new
    )

    cnf_testsuite = find_stdout.to_s.split("\n").select{ |x| x.empty? == false }
    Log.info { "find response: #{cnf_testsuite}" }
    if cnf_testsuite.size == 0 && !silent
      raise "No cnf_testsuite.yml found! Did you run the setup task?"
    end
    cnf_testsuite
  end
  
  def self.cnf_installed?
    cnf_configs = self.cnf_config_list(silent: true)
    
    if cnf_configs.size == 0
      false
    else
      true
    end
  end

  def self.destination_cnfs_exist?
    cnf_config_list(silent: true).size > 0
  end

  def self.path_has_yml?(config_path)
    if config_path =~ /\.yml/
      true
    else
      false
    end
  end

  # if passed a directory, adds cnf-testsuite.yml to the string
  def self.ensure_cnf_testsuite_yml_path(path : String)
    Log.info { "ensure_cnf_testsuite_yml_path" }
    if path_has_yml?(path)
      yml = path
    else
      yml = path + "/cnf-testsuite.yml"
    end
  end

  def self.ensure_cnf_testsuite_dir(path : String)
    Log.info { "ensure_cnf_testsuite_yml_dir" }
    if path_has_yml?(path)
      dir = File.dirname(path)
    else
      dir = path
    end
    dir + "/"
  end

  def self.sandbox_helm_directory(cnf_testsuite_helm_directory)
    cnf_testsuite_helm_directory.split("/")[-1]
  end

  def self.config_source_dir(config_file)
    if File.directory?(config_file)
      config_file
    else
      File.dirname(config_file)
    end
  end

  def self.helm_repo_add(helm_repo_name=nil, helm_repo_url=nil, args : Sam::Args=Sam::Args.new)
    Log.info { "helm_repo_add repo_name: #{helm_repo_name} repo_url: #{helm_repo_url} args: #{args.inspect}" }
    ret = false
    if helm_repo_name == nil || helm_repo_url == nil
      config = CNFInstall::Config.parse_cnf_config_from_file(CNFManager.ensure_cnf_testsuite_yml_path(args.named["cnf-config"].as(String)))
      Log.info { "helm path: #{Helm::BinarySingleton.helm}" }
      helm = Helm::BinarySingleton.helm
      helm_repo_name = config.deployments.get_deployment_param(:helm_repo_name)
      helm_repo_url = config.deployments.get_deployment_param(:helm_repo_url)
      Log.info { "helm_repo_name: #{helm_repo_name}" }
      Log.info { "helm_repo_url: #{helm_repo_url}" }
    end
    if helm_repo_name && helm_repo_url
      ret = Helm.helm_repo_add(helm_repo_name, helm_repo_url)
    else
      ret = false
    end
    ret
  end

  def self.sample_setup_cli_args(args, noisy=true)
    Log.for("verbose").info { "sample_setup_cli_args" } if check_verbose(args)
    Log.for("verbose").debug { "args = #{args.inspect}" } if check_verbose(args)
    cnf_path = ""
    if args.named.keys.includes? "cnf-config"
      cnf_path = args.named["cnf-config"].as(String)
    elsif args.named.keys.includes? "cnf-path"
      cnf_path = args.named["cnf-path"].as(String)
    elsif noisy
      stdout_failure "Error: You must supply either cnf-config or cnf-path"
      exit 1
    else
      cnf_path = ""
    end
    if args.named.keys.includes? "wait_count"
      wait_count = args.named["wait_count"].to_i
    elsif args.named.keys.includes? "wait-count"
      wait_count = args.named["wait-count"].to_i
    else
      wait_count = 1800
    end

    skip_wait_for_install = args.raw.includes? "skip_wait_for_install"

    cli_args = {config_file: cnf_path, wait_count: wait_count, skip_wait_for_install: skip_wait_for_install, verbose: check_verbose(args)}
    Log.debug { "cli_args: #{cli_args}" }
    cli_args
  end

  # Create a unique directory for the cnf that is to be installed under ./cnfs
  # Only copy the cnf's cnf-testsuite.yml and it's helm_directory or manifest directory (if it exists)
  # Use manifest directory if helm directory empty
  def self.sandbox_setup(config, cli_args)
    Log.info { "sandbox_setup" }
    Log.info { "sandbox_setup config: #{config.inspect}" }
    verbose = cli_args[:verbose]
    config_file = config.dynamic.source_cnf_dir
    install_method = config.dynamic.install_method
    destination_cnf_dir = config.dynamic.destination_cnf_dir

    # Create a CNF sandbox dir
    FileUtils.mkdir_p(destination_cnf_dir)

    # Copy cnf-testsuite.yml file to the cnf sandbox dir
    copy_cnf_cmd = "cp -a #{ensure_cnf_testsuite_yml_path(config_file)} #{destination_cnf_dir}"
    Log.info { copy_cnf_cmd }
    status = Process.run(copy_cnf_cmd, shell: true)

    # Create dir for config maps
    FileUtils.mkdir_p("#{destination_cnf_dir}/config_maps")

    # todo manifest_or_helm_directory should either be the source helm/manifest files or the destination
    # directory that they will be copied to/generated into, but *not both*
    case install_method[0]
    when CNFInstall::InstallMethod::ManifestDirectory
      Log.info { "preparing manifest_directory sandbox" }
      manifest_directory = config.deployments.get_deployment_param(:manifest_directory)
      source_directory = File.join(config_source_dir(config_file), manifest_directory)
      src_path = Path[source_directory].expand.to_s
      Log.info { "cp -a #{src_path} #{destination_cnf_dir}" }

      begin
        FileUtils.cp_r(src_path, destination_cnf_dir)
      rescue File::AlreadyExistsError
        Log.info { "manifest sandbox dir already exists at #{destination_cnf_dir}/#{File.basename(src_path)}" }
      end
    when CNFInstall::InstallMethod::HelmDirectory
      Log.info { "preparing helm_directory sandbox" }
      helm_directory = config.deployments.get_deployment_param(:helm_directory)
      source_directory = File.join(config_source_dir(config_file), helm_directory.split(" ")[0]) # todo support parameters separately
      src_path = Path[source_directory].expand.to_s
      Log.info { "cp -a #{src_path} #{destination_cnf_dir}" }

      begin
        FileUtils.cp_r(src_path, destination_cnf_dir)
      rescue File::AlreadyExistsError
        Log.info { "helm sandbox dir already exists at #{destination_cnf_dir}/#{File.basename(src_path)}" }
      rescue File::NotFoundError
        Log.info { "helm directory not found at #{src_path}" }
        stdout_warning "helm directory at #{helm_directory} is missing"
      end
    when CNFInstall::InstallMethod::HelmChart
      Log.info { "preparing helm chart sandbox" }
      FileUtils.mkdir_p(Path[destination_cnf_dir].expand.to_s + "/exported_chart")
    end

    Log.for("verbose").debug {
      stdout = IO::Memory.new
      Process.run("ls -alR #{destination_cnf_dir}", shell: true, output: stdout, error: stdout)
      "Contents of destination_cnf_dir #{destination_cnf_dir}: \n#{stdout}"
    }
  end

  # Retrieve the helm chart source: only works with helm chart
  # installs (not helm directory or manifest directories)
  def self.export_published_chart(config, cli_args)
    Log.info { "exported_chart cli_args: #{cli_args}" }
    verbose = cli_args[:verbose]
    config_file = config.dynamic.source_cnf_dir
    helm_chart = config.deployments.get_deployment_param(:helm_chart)
    destination_cnf_dir = config.dynamic.destination_cnf_dir
    config_path = CNFManager.ensure_cnf_testsuite_yml_path(config_file)

    # Pulling chart 
    # Delete pre-existing tgz files
    files_to_delete = find_tgz_files(helm_chart)
    files_to_delete.each do |file|
      FileUtils.rm(file)
      Log.info { "Deleted: #{file}" }
    end

    # Pull new version
    helm_info = Helm.pull(helm_chart)
    unless helm_info[:status].success?
      puts "Helm pull error".colorize(:red)
      raise "Helm pull error"
    end

    # Discover newly pulled tgz file
    tgz_name = get_and_verify_tgz_name(helm_chart)

    Log.info { "tgz_name: #{tgz_name}" }

    TarClient.untar(tgz_name, "#{destination_cnf_dir}/exported_chart")

    Log.for("verbose").info { "mv #{destination_cnf_dir}/exported_chart/#{Helm.chart_name(helm_chart)}/* #{destination_cnf_dir}/exported_chart" } if verbose
    Log.for("verbose").debug {
      stdout = IO::Memory.new
      Process.run("ls -alR #{destination_cnf_dir}", shell: true, output: stdout, error: stdout)
      "Contents of destination_cnf_dir #{destination_cnf_dir} before move: \n#{stdout}"
    }

    FileUtils.mv(
      Dir.glob("#{destination_cnf_dir}/exported_chart/#{Helm.chart_name(helm_chart)}/*"),
      "#{destination_cnf_dir}/exported_chart"
    )

    Log.for("verbose").debug {
      stdout = IO::Memory.new
      Process.run("ls -alR #{destination_cnf_dir}", shell: true, output: stdout, error: stdout)
      "Contents of destination_cnf_dir #{destination_cnf_dir} after move: \n#{stdout}"
    }
  end

  #sample_setup({config_file: cnf_path, wait_count: wait_count})
  def self.sample_setup(cli_args)
    Log.info { "sample_setup cli_args: #{cli_args}" }
    config_file = cli_args[:config_file]
    wait_count = cli_args[:wait_count]
    skip_wait_for_install = cli_args[:skip_wait_for_install]
    verbose = cli_args[:verbose]
    config = CNFInstall::Config.parse_cnf_config_from_file(CNFManager.ensure_cnf_testsuite_yml_path(config_file))
    Log.debug { "config in sample_setup: #{config.inspect}" }

    Log.for("verbose").info { "sample_setup" } if verbose
    Log.info { "config_file #{config_file}" }

    release_name = config.deployments.get_deployment_param(:name)
    install_method = config.dynamic.install_method
    Log.info { "install_method #{install_method}" }
    helm_values = config.deployments.get_deployment_param(:helm_values)
    deployment_namespace = CNFManager.get_deployment_namespace(config)
    helm_namespace_option = "-n #{deployment_namespace}"
    ensure_namespace_exists!(deployment_namespace)
    destination_cnf_dir = config.dynamic.destination_cnf_dir

    Log.for("verbose").info { "destination_cnf_dir: #{destination_cnf_dir}" } if verbose
    Log.debug { "mkdir_p destination_cnf_dir: #{destination_cnf_dir}" }
    FileUtils.mkdir_p(destination_cnf_dir)

    sandbox_setup(config, cli_args)

    helm = Helm::BinarySingleton.helm
    Log.info { "helm path: #{Helm::BinarySingleton.helm}" }

    # This is to indicate if the release has already been setup.
    # Set it to false by default to indicate a new release is being setup
    fresh_install = true

    helm_install = {status: nil, output: "", error: ""}

    # todo determine what the ric is/if there is a ric installed (labeling)
    #option 1
    # todo determine what pad/node the ric is in  (pod/node by label)
    # todo start tshark capture of the e2 traffic 
    # todo restart the ric pod when running the ric e2 test
    # todo validate the e2 traffic
    #option 2
    # todo start tshark capture of the e2 traffic (on all nodes?)
    # todo install the ric/xapp (the xapp should be installed last?)
    # todo note which pad/node the ric is in  (what if cluster tools tshark was  not executed on the node with the ric?)
    # todo alternative (capture on gnodeb node)
    # todo validate the e2 traffic
    # todo save off the result to a config map
    # todo check the config map in the e2 test

    match = JaegerManager.match()
    if match[:found]
      baselines = JaegerManager.unique_services_total
      Log.info { "baselines: #{baselines}" }
    end

    # todo start tshark monitoring the e2 traffic 
    capture = ORANMonitor.start_e2_capture?(config)

    # todo separate out install methods into a module/function that accepts a block
    liveness_time = 0
    Log.for("sample_setup:install_method").info { "#{install_method[0]}" }
    Log.for("sample_setup:install_method").info { "#{install_method[1]}" }
    elapsed_time = Time.measure do
      case install_method[0]
      when CNFInstall::InstallMethod::ManifestDirectory
        Log.for("verbose").info { "deploying by manifest file" } if verbose
        manifest_directory = config.deployments.get_deployment_param(:manifest_directory)
        KubectlClient::Apply.file("#{destination_cnf_dir}/#{manifest_directory}")
      when CNFInstall::InstallMethod::HelmChart
        helm_chart = config.deployments.get_deployment_param(:helm_chart)
        helm_repo_name = config.deployments.get_deployment_param(:helm_repo_name)
        helm_repo_url = config.deployments.get_deployment_param(:helm_repo_url)
        if !helm_repo_name.empty? || !helm_repo_url.empty?
          Helm.helm_repo_add(helm_repo_name, helm_repo_url)
        end
        Log.for("verbose").info { "deploying with chart repository" } if verbose
        begin
          helm_install = Helm.install(release_name, helm_chart, helm_namespace_option, helm_values)
        rescue e : Helm::InstallationFailed
          stdout_failure "Helm installation failed"
          stdout_failure "\t#{e.message}"
          exit 1
        rescue e : Helm::CannotReuseReleaseNameError
          stdout_warning "Release name #{release_name} has already been setup."
          # Mark that install is not fresh
          fresh_install = false
        end
        export_published_chart(config, cli_args)
      when CNFInstall::InstallMethod::HelmDirectory
        Log.for("verbose").info { "deploying with helm directory" } if verbose
        #TODO Add helm options into cnf-testsuite yml
        #e.g. helm install nsm --set insecure=true ./nsm/helm_chart
        begin
          helm_install = Helm.install(release_name, "#{install_method[1]}", helm_namespace_option, helm_values)
        rescue e : Helm::InstallationFailed
          stdout_failure "Helm installation failed"
          stdout_failure "\t#{e.message}"
          exit 1
        rescue e : Helm::CannotReuseReleaseNameError
          stdout_warning "Release name #{release_name} has already been setup."
          # Mark that install is not fresh
          fresh_install = false
        end
      else
        raise "Deployment method not found"
      end
      
      #Generating manifest from installed CNF
      #Returns true or false in case when manifest was generated successfully or not
      manifest_generated_successfully = CNFInstall::Manifest.generate_common_manifest(config, release_name, deployment_namespace)
      
      if !manifest_generated_successfully
        stdout_failure "Manifest generation failed. Check CNF definition (helm charts, values, manifests, etc.)"
        exit 1
      end

      resource_ymls = cnf_workload_resources(nil, config) do |resource|
        resource
      end

      resource_names = Helm.workload_resource_kind_names(resource_ymls, deployment_namespace)
      #TODO move to kubectlclient and make resource_install_and_wait_for_all function
      # get liveness probe initialDelaySeconds and FailureThreshold
      # if   ((periodSeconds * failureThreshhold) + initialDelaySeconds) / defaultFailureThreshold) > startuptimelimit then fail; else pass
      # get largest startuptime of all resoures, then save into config map
      resource_ymls.map do |resource|
        kind = resource["kind"].as_s.downcase
        case kind 
        when  "pod"
          Log.info { "resource: #{resource}" }
          containers = resource.dig("spec", "containers")
        when  "deployment","statefulset","replicaset","daemonset"
          Log.info { "resource: #{resource}" }
          containers = resource.dig("spec", "template", "spec", "containers")
        end
        containers && containers.as_a.map do |container|
          initialDelaySeconds = container.dig?("livenessProbe", "initialDelaySeconds")
          failureThreshhold = container.dig?("livenessProbe", "failureThreshhold")
          periodSeconds = container.dig?("livenessProbe", "periodSeconds")
          total_period_failure = 0 
          total_extended_period = 0
          adjusted_with_default = 0
          defaultFailureThreshold = 3
          defaultPeriodSeconds = 10

          if !failureThreshhold.nil? && failureThreshhold.as_i?
            ft = failureThreshhold.as_i
          else
            ft = defaultFailureThreshold
          end

          if !periodSeconds.nil? && periodSeconds.as_i?
            ps = periodSeconds.as_i
          else
            ps = defaultPeriodSeconds
          end

          total_period_failure = ps * ft

          if !initialDelaySeconds.nil? && initialDelaySeconds.as_i?
            total_extended_period = initialDelaySeconds.as_i + total_period_failure
          else
            total_extended_period = total_period_failure
          end

          adjusted_with_default = (total_extended_period / defaultFailureThreshold).round.to_i

          Log.info { "total_period_failure: #{total_period_failure}" }
          Log.info { "total_extended_period: #{total_extended_period}" }
          Log.info { "liveness_time: #{liveness_time}" }
          Log.info { "adjusted_with_default: #{adjusted_with_default}" }
          if liveness_time < adjusted_with_default
            liveness_time = adjusted_with_default
          end
        end
      end
      if !skip_wait_for_install
        stdout_success "Waiting for resource availability, timeout for each resource is #{wait_count} seconds\n"
        workload_resource_names = resource_names.select { |resource| 
        ["replicaset", "deployment", "statefulset", "pod", "daemonset"].includes?(resource[:kind].downcase) 
      }
        total_resource_count = workload_resource_names.size()
        current_resource_number = 1
        workload_resource_names.each do | resource |
          stdout_success "Waiting for resource (#{current_resource_number}/#{total_resource_count}): [#{resource[:kind]}] #{resource[:name]}", same_line: true
          ready = KubectlClient::Get.resource_wait_for_install(resource[:kind], resource[:name], wait_count: wait_count, namespace: resource[:namespace])
          if !ready
            stdout_failure "CNF setup has timed-out, [#{resource[:kind]}] #{resource[:name]} is not ready after #{wait_count} seconds.", same_line: true
            stdout_failure "Recommended course of actions would be to investigate the resource in cluster, then call cnf_cleanup and try to reinstall the CNF."
            exit 1
          end
          current_resource_number += 1
        end
        stdout_success "All CNF resources are up!", same_line: true
      end
    end

    if match[:found]
      sleep 120
      metrics_checkpoints = JaegerManager.unique_services_total
      Log.info { "metrics_checkpoints: #{metrics_checkpoints}" }
      tracing_used = JaegerManager.tracing_used?(baselines, metrics_checkpoints)
      Log.info { "tracing_used: #{tracing_used}" }
    else
      tracing_used = false
    end

    if ORANMonitor.isCNFaRIC?(config)
      sleep 30 
      e2_found = ORANMonitor.e2_session_established?(capture)
    else
      e2_found = false
    end

    Log.info { "final e2_found: #{e2_found}" }
    Log.info { "final liveness_time: #{liveness_time}" }
    Log.info { "elapsed_time.seconds: #{elapsed_time.seconds}" }
    Log.info { "helm_install: #{helm_install}" }
    Log.info { "helm_install[:error].to_s: #{helm_install[:error].to_s}" }
    Log.info { "helm_install[:error].to_s.size: #{helm_install[:error].to_s.size}" }

    if fresh_install
      stdout_success "Successfully setup #{release_name}"
    end

    # Not required to write elapsed time configmap if the cnf already exists due to a previous Helm install
    return true if !fresh_install

    # Immutable config maps are only supported in Kubernetes 1.19+
    immutable_configmap = true
    if version_less_than(KubectlClient.server_version, "1.19.0")
      immutable_configmap = false
    end

    helm_used = !helm_install[:status].nil?
    #TODO if helm_install then set helm_deploy = true in template
    Log.info { "save config" }
    elapsed_time_template = ElapsedTimeConfigMapTemplate.new(
      "cnf-testsuite-#{release_name}-startup-information",
      helm_used,
      # "#{elapsed_time.seconds}",
      "#{liveness_time}",
      immutable_configmap,
      tracing_used,
      e2_found
    ).to_s
    #TODO find a way to kubectlapply directly without a map
    Log.debug { "elapsed_time_template : #{elapsed_time_template}" }
    configmap_path = "#{destination_cnf_dir}/config_maps/elapsed_time.yml"
    File.write(configmap_path, "#{elapsed_time_template}")
    # TODO if the config map exists on install, complain, delete then overwrite?
    KubectlClient::Delete.file(configmap_path)
    #TODO call kubectl apply on file
    KubectlClient::Apply.file(configmap_path)
    # TODO when uninstalling, remove config map
  ensure
    #todo uninstall/reinstall clustertools because of tshark bug
  end

  def self.cnf_to_new_cluster(config, kubeconfig)
    release_name = config.deployments.get_deployment_param(:name)
    install_method = config.dynamic.install_method
    destination_cnf_dir = config.dynamic.destination_cnf_dir
    deployment_namespace = CNFManager.get_deployment_namespace(config)
    helm_namespace_option = "-n #{deployment_namespace}"
    ensure_namespace_exists!(deployment_namespace, kubeconfig: kubeconfig)

    Log.for("cnf_to_new_cluster").info { "Install method: #{install_method[0]}" }
    case install_method[0]
    when CNFInstall::InstallMethod::ManifestDirectory
      manifest_directory = config.deployments.get_deployment_param(:manifest_directory)
      KubectlClient::Apply.file("#{destination_cnf_dir}/#{manifest_directory}", kubeconfig: kubeconfig)
    when CNFInstall::InstallMethod::HelmChart
      helm_repo_name = config.deployments.get_deployment_param(:helm_repo_name)
      helm_repo_url = config.deployments.get_deployment_param(:helm_repo_url)
      helm_chart = config.deployments.get_deployment_param(:helm_chart)
      begin
        helm_install = Helm.install("#{release_name} #{helm_chart} --kubeconfig #{kubeconfig} #{helm_namespace_option}")
      rescue e : Helm::CannotReuseReleaseNameError
        stdout_warning "Release name #{release_name} has already been setup."
      end
    when CNFInstall::InstallMethod::HelmDirectory
      helm_directory = config.deployments.get_deployment_param(:helm_directory)
      begin
        helm_install = Helm.install("#{release_name} #{destination_cnf_dir}/#{helm_directory} --kubeconfig #{kubeconfig} #{helm_namespace_option}")
      rescue e : Helm::CannotReuseReleaseNameError
        stdout_warning "Release name #{release_name} has already been setup."
      end
    else
      raise "Deployment method not found"
    end

    resource_ymls = cnf_workload_resources(nil, config) do |resource|
      resource
    end

    resource_names = Helm.workload_resource_kind_names(resource_ymls, default_namespace: deployment_namespace)

    wait_list = resource_names.map do | resource |
      case resource[:kind].downcase
      when "replicaset", "deployment", "statefulset", "pod", "daemonset"
        Log.info { "waiting on resource of kind: #{resource[:kind].downcase}" }
        KubectlClient::Get.resource_wait_for_install(resource[:kind], resource[:name], 180, namespace: resource[:namespace], kubeconfig: kubeconfig)
      else 
        true
      end
    end
    Log.info { "wait_list: #{wait_list}" }
    # check list of booleans, make sure all are true (is ready)
    !wait_list.any?(false)
  end

  def self.sample_cleanup(config_file, force=false, installed_from_manifest=false, verbose=true)
    Log.info { "sample_cleanup" }
    Log.info { "sample_cleanup installed_from_manifest: #{installed_from_manifest}" }

    FileUtils.rm_rf(COMMON_MANIFEST_FILE_PATH)
    Log.info { "#{COMMON_MANIFEST_FILE_PATH} file was removed." }

    config = CNFInstall::Config.parse_cnf_config_from_file(CNFManager.ensure_cnf_testsuite_yml_path(config_file))
    Log.for("verbose").info { "cleanup config: #{config.inspect}" } if verbose
    destination_cnf_dir = config.dynamic.destination_cnf_dir
    Log.info { "destination_cnf_dir: #{destination_cnf_dir}" }
    

    config_maps_dir = "#{destination_cnf_dir}/config_maps"
    if Dir.exists?(config_maps_dir)
      Dir.entries(config_maps_dir).each do |config_map|
        Log.info { "Deleting configmap: #{config_map}" }
        KubectlClient::Delete.file("#{destination_cnf_dir}/config_maps/#{config_map}")
      end
    end

    # Strips all the helm options from the release name option in config
    release_name = config.deployments.get_deployment_param(:name)
    release_name = release_name.split(" ")[0]

    Log.for("sample_cleanup:helm_path").info { Helm::BinarySingleton.helm }
    helm = Helm::BinarySingleton.helm
    dir_exists = File.directory?(destination_cnf_dir)
    if !dir_exists && force != true
      Log.for("sample_cleanup").info { "Destination dir #{destination_cnf_dir} does not exist and force option not passed. Exiting." }
      return false
    elsif dir_exists
      Log.for("sample_cleanup").info { "Destination dir #{destination_cnf_dir} exists" }
    end
    
    install_method = config.dynamic.install_method
    Log.for("sample_cleanup:install_method").info { install_method }
    case install_method[0]
    when CNFInstall::InstallMethod::HelmChart, CNFInstall::InstallMethod::HelmDirectory
      deployment_namespace = CNFManager.get_deployment_namespace(config)
      helm_namespace_option = "-n #{deployment_namespace}"
      result = Helm.uninstall(release_name + " #{helm_namespace_option}")
      Log.for("sample_cleanup:helm_uninstall").info { result[:output].to_s } if verbose
      if result[:status].success?
        stdout_success "Successfully cleaned up #{release_name}"
      end
      FileUtils.rm_rf(destination_cnf_dir)
      return result[:status].success?
    when CNFInstall::InstallMethod::ManifestDirectory
      manifest_directory = config.deployments.get_deployment_param(:manifest_directory)
      installed_manifest_directory = File.join(destination_cnf_dir, manifest_directory)
      Log.for("cnf_cleanup:installed_manifest_directory").info { installed_manifest_directory }
      result = KubectlClient::Delete.file("#{installed_manifest_directory}", wait: true)
      FileUtils.rm_rf(destination_cnf_dir)
      stdout_success "Successfully cleaned up #{manifest_directory} directory"
      return true
    end
  end

  def self.ensure_namespace_exists!(name, kubeconfig : String | Nil = nil)
    KubectlClient::Create.namespace(name, kubeconfig: kubeconfig)
    Log.for("ensure_namespace_exists").info { "Created kubernetes namespace #{name} for the CNF install" }
  rescue e : KubectlClient::Create::AlreadyExistsError
    Log.for("ensure_namespace_exists").info { "Kubernetes namespace #{name} already exists for the CNF install" }
  end

  def self.workload_resource_keys(args, config)
    resource_keys = CNFManager.cnf_workload_resources(args, config) do |resource|
      deployment_namespace = CNFManager.get_deployment_namespace(config)
      namespace = resource.dig?("metadata", "namespace") || deployment_namespace
      kind = resource.dig?("kind")
      name = resource.dig?("metadata", "name")
      "#{namespace},#{kind}/#{name}".downcase
    end
    resource_keys
  end

  def self.resources_includes?(resource_keys, kind, name, namespace)
    resource_key = "#{namespace},#{kind}/#{name}".downcase
    resource_keys.includes?(resource_key)
  end

  def self.find_tgz_files(helm_chart)
    Dir.glob(get_helm_tgz_glob(helm_chart))
  end

  def self.get_and_verify_tgz_name(helm_chart)
    tgz_files = find_tgz_files(helm_chart)
    
    if tgz_files.empty?
      Log.error { "No .tgz files found for #{get_helm_tgz_glob(helm_chart)}" }
      raise TarFileNotFoundError.new(Helm.chart_name(helm_chart))
    elsif tgz_files.size > 1
      Log.warn { "Multiple .tgz files found: #{tgz_files.join(", ")}" }
    end
  
    tgz_files.first
  end

  def self.get_helm_tgz_glob(helm_chart)
    "#{Helm.chart_name(helm_chart)}-*.tgz"
  end

  class TarFileNotFoundError < Exception
    def initialize(chart_name)
      super("No .tgz files found for chart #{chart_name}-*.tgz")
    end
  end
end
