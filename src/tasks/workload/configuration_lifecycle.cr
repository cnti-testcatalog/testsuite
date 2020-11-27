# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "json"
require "../utils/utils.cr"

desc "Configuration and lifecycle should be managed in a declarative manner, using ConfigMaps, Operators, or other declarative interfaces."
task "configuration_lifecycle", ["ip_addresses", "liveness", "readiness", "rolling_update", "nodeport_not_used", "hardcoded_ip_addresses_in_k8s_runtime_configuration"]  do |_, args|
  stdout_score("configuration_lifecycle")
end

desc "Does a search for IP addresses or subnets come back as negative?"
task "ip_addresses" do |_, args|
  task_runner(args) do |args|
    VERBOSE_LOGGING.info "ip_addresses" if check_verbose(args)
    LOGGING.info("ip_addresses args #{args.inspect}")
    cdir = FileUtils.pwd()
    response = String::Builder.new
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    helm_directory = "#{config.get("helm_directory").as_s?}" 
    LOGGING.info "ip_addresses helm_directory: #{CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)) + helm_directory}"
    if File.directory?(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)) + helm_directory)
      # Switch to the helm chart directory
      Dir.cd(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)) + helm_directory)
      # Look for all ip addresses that are not comments
      LOGGING.info "current directory: #{ FileUtils.pwd()}"
      # should catch comments (# // or /*) and ignore 0.0.0.0
      # note: grep wants * escaped twice
      Process.run("grep -r -P '^(?!.+0\.0\.0\.0)(?![[:space:]]*0\.0\.0\.0)(?!#)(?![[:space:]]*#)(?!\/\/)(?![[:space:]]*\/\/)(?!\/\\*)(?![[:space:]]*\/\\*)(.+([0-9]{1,3}[\.]){3}[0-9]{1,3})'", shell: true) do |proc|
        while line = proc.output.gets
          response << line
          VERBOSE_LOGGING.info "#{line}" if check_verbose(args)
        end
      end
      Dir.cd(cdir)
      if response.to_s.size > 0
        resp = upsert_failed_task("ip_addresses","✖️  FAILURE: IP addresses found")
      else
        resp = upsert_passed_task("ip_addresses", "✔️  PASSED: No IP addresses found")
      end
      resp
    else
      # TODO If no helm chart directory, exit with 0 points
      Dir.cd(cdir)
      resp = upsert_passed_task("ip_addresses", "✔️  PASSED: No IP addresses found")
    end
  end
end

desc "Is there a liveness entry in the helm chart?"
task "liveness", ["retrieve_manifest"] do |_, args|
  task_runner(args) do |args|
    VERBOSE_LOGGING.info "liveness" if check_verbose(args)
    # Parse the cnf-conformance.yml
    resp = ""
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    emoji_probe="🧫"
    yml_file_path = CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String))
    LOGGING.info("reasonable_startup_time yml_file_path: #{yml_file_path}")
    VERBOSE_LOGGING.info "yaml_path: #{yml_file_path}" if check_verbose(args)
    helm_chart = "#{config.get("helm_chart").as_s?}"
    release_name = "#{config.get("release_name").as_s?}"
    helm_chart_path = yml_file_path + "/" + helm_chart
    manifest_file_path = yml_file_path + "/" + "temp_template.yml"
    # get the manifest file from the helm chart
    # TODO if no release name, then assume bare manifest file/directory with no helm chart
    Helm.generate_manifest_from_templates(release_name, 
                                          helm_chart_path, 
                                          manifest_file_path)
    template_ymls = Helm.read_template_as_ymls(manifest_file_path) 
    deployment_ymls = Helm.workload_resource_by_kind(template_ymls, "deployment")
    deployment_names = Helm.workload_resource_names(deployment_ymls)
    test_passed = true
		deployment_names.each do | deployment |
			VERBOSE_LOGGING.debug deployment.inspect if check_verbose(args)
			containers = KubectlClient::Get.deployment_containers(deployment)
			containers.as_a.each do |container|
				begin
					VERBOSE_LOGGING.debug container.as_h["name"].as_s if check_verbose(args)
					container.as_h["livenessProbe"].as_h 
				rescue ex
					VERBOSE_LOGGING.error ex.message if check_verbose(args)
					test_passed = false 
          puts "No livenessProbe found for deployment: #{deployment} and container: #{container.as_h["name"].as_s}".colorize(:red)
				end
			end
		end
    if test_passed 
      resp = upsert_passed_task("liveness","✔️  PASSED: Helm liveness probe found #{emoji_probe}")
		else
			resp = upsert_failed_task("liveness","✖️  FAILURE: No livenessProbe found #{emoji_probe}")
    end
    resp
  end
end

desc "Is there a readiness entry in the helm chart?"
task "readiness", ["retrieve_manifest"] do |_, args|
  task_runner(args) do |args|
    VERBOSE_LOGGING.info "readiness" if check_verbose(args)
    # Parse the cnf-conformance.yml
    resp = ""
    errors = 0
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    deployment = Totem.from_file "#{destination_cnf_dir}/manifest.yml"
    VERBOSE_LOGGING.debug deployment.inspect if check_verbose(args)
    containers = deployment.get("spec").as_h["template"].as_h["spec"].as_h["containers"].as_a
    containers.each do |container|
     begin
        VERBOSE_LOGGING.debug container.as_h["name"].as_s if check_verbose(args)
        container.as_h["readinessProbe"].as_h 
      rescue ex
        VERBOSE_LOGGING.error ex.message if check_verbose(args)
        errors = errors + 1
        resp = upsert_failed_task("readiness","✖️  FAILURE: No readinessProbe found")
      end
    end
    if errors == 0
      resp = upsert_passed_task("readiness","✔️  PASSED: Helm readiness probe found")
    end
  end
end

desc "Retrieve the manifest for the CNF's helm chart"
task "retrieve_manifest" do |_, args| 
  # TODO put this in a function 
  task_runner(args) do |args|
    VERBOSE_LOGGING.info "retrieve_manifest" if check_verbose(args)
    # config = cnf_conformance_yml
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    deployment_name = config.get("deployment_name").as_s
    # TODO get this from k8s manifest kind = service
    service_name = "#{config.get("service_name").as_s?}"
    VERBOSE_LOGGING.debug "Deployment_name: #{deployment_name}" if check_verbose(args)
    VERBOSE_LOGGING.debug service_name if check_verbose(args)
    helm_directory = config.get("helm_directory").as_s
    VERBOSE_LOGGING.debug helm_directory if check_verbose(args)
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    # TODO move to kubectl client
    deployment = `kubectl get deployment #{deployment_name} -o yaml  > #{destination_cnf_dir}/manifest.yml`
    # KubectlClient::Get.save_manifest(deployment_name, "#{destination_cnf_dir}/manifest.yml")
    VERBOSE_LOGGING.debug deployment if check_verbose(args)
    unless service_name.empty?
      # TODO move to kubectl client
      service = `kubectl get service #{service_name} -o yaml  > #{destination_cnf_dir}/service.yml`
    end
    VERBOSE_LOGGING.debug service if check_verbose(args)
    service
  end
end

desc "Test if the CNF containers are loosely coupled by performing a rolling update"
task "rolling_update" do |_, args|
  task_runner(args) do |args|
    # TODO mark as destructive?
    VERBOSE_LOGGING.info "rolling_update" if check_verbose(args)
    # config = cnf_conformance_yml
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))

    # TODO use tag associated with image name string (e.g. busybox:v1.7.9) as the version tag
    # TODO optional get a valid version from the remote repo and roll to that, if no tag
    #  e.g. wget -q https://registry.hub.docker.com/v1/repositories/debian/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}'
    # note: all images are not on docker hub nor are they always on a docker hub compatible api

    release_name = config.get("release_name").as_s
    deployment_name = config.get("deployment_name").as_s
    containers = KubectlClient::Get.deployment_containers(deployment_name)

    container_names = config["container_names"]?
    LOGGING.debug "container_names: #{container_names}"

    unless container_names && !container_names.as_a.empty?
      puts "Please add a container names set of entries into your cnf-conformance.yml".colorize(:red) unless container_names
      upsert_failed_task("rolling_update", "✖️  FAILURE: CNF #{deployment_name} Rolling Update Failed")
      exit 0
    end

    valid_cnf_conformance_yml = true
    containers.as_a.each do | container |
      LOGGING.debug "rolling update container: #{container}"
      config_container = container_names.as_a.find{|x| x["name"]==container.as_h["name"]} if container_names
      LOGGING.debug "config_container: #{config_container}"
      unless config_container && config_container["upgrade_test_tag"]? && !config_container["upgrade_test_tag"].as_s.empty?
        puts "Please add the container name #{container.as_h["name"]} and a corresponding upgrade_test_tag into your cnf-conformance.yml under container names".colorize(:red)
        valid_cnf_conformance_yml = false
      end
    end
    unless valid_cnf_conformance_yml
      upsert_failed_task("rolling_update", "✖️  FAILURE: CNF #{deployment_name} Rolling Update Failed")
      exit 0
    end

    if containers.as_a.empty?
      update_applied = false 
    else
      update_applied = true 
    end
    containers.as_a.each do | container |
      LOGGING.debug "rolling update container: #{container}"
      config_container = container_names.as_a.find{|x| x["name"]==container.as_h["name"]} if container_names
      LOGGING.debug "config container: #{config_container}"
      if config_container
        resp = KubectlClient::Set.image(deployment_name, 
                                      container.as_h["name"], 
                                      # split out image name from version tag
                                      container.as_h["image"].as_s.split(":")[0], 
                                      config_container["upgrade_test_tag"].as_s) 
      else 
        resp = false
      end
      # If any containers dont have an update applied, fail
      update_applied = false if resp == false
    end

    rollout_status = KubectlClient::Rollout.status(deployment_name)
    if update_applied && rollout_status
      upsert_passed_task("rolling_update","✔️  PASSED: CNF #{deployment_name} Rolling Update Passed" )
    else
      upsert_failed_task("rolling_update", "✖️  FAILURE: CNF #{deployment_name} Rolling Update Failed")
    end
    # TODO should we roll the image back to original version in an ensure? 
    # TODO Use the kubectl rollback to history command
  end
end

desc "Does the CNF use NodePort"
task "nodeport_not_used", ["retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "nodeport_not_used" if check_verbose(args)
    # config = cnf_conformance_yml
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    release_name = config.get("release_name").as_s
    service_name = "#{config.get("service_name").as_s?}"
    # current_cnf_dir_short_name = CNFManager.ensure_cnf_conformance_dir
    # VERBOSE_LOGGING.debug current_cnf_dir_short_name if check_verbose(args)
    # destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    if File.exists?("#{destination_cnf_dir}/service.yml")
      service = Totem.from_file "#{destination_cnf_dir}/service.yml"
      VERBOSE_LOGGING.debug service.inspect if check_verbose(args)
      service_type = service.get("spec").as_h["type"].as_s
      VERBOSE_LOGGING.debug service_type if check_verbose(args)
      if service_type == "NodePort" 
        upsert_failed_task("nodeport_not_used", "✖️  FAILURE: NodePort is being used")
      else
        upsert_passed_task("nodeport_not_used", "✔️  PASSED: NodePort is not used")
      end
    else
      upsert_passed_task("nodeport_not_used", "✔️  PASSED: NodePort is not used")
    end
  end
end

desc "Does the CNF have hardcoded IPs in the K8s resource configuration"
task "hardcoded_ip_addresses_in_k8s_runtime_configuration" do |_, args|
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "Task Name: hardcoded_ip_addresses_in_k8s_runtime_configuration" if check_verbose(args)
    # config = cnf_conformance_yml
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    helm_chart = "#{config.get("helm_chart").as_s?}"
    helm_directory = config.get("helm_directory").as_s
    release_name = "#{config.get("release_name").as_s?}"
    # current_cnf_dir_short_name = CNFManager.ensure_cnf_conformance_dir
    # VERBOSE_LOGGING.debug "Current_CNF_Dir: #{current_cnf_dir_short_name}" if check_verbose(args)
    # destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)

    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    current_dir = FileUtils.pwd
    #helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    helm = CNFSingleton.helm
    VERBOSE_LOGGING.info "Helm Path: #{helm}" if check_verbose(args)

    create_namespace = `kubectl create namespace hardcoded-ip-test`
    unless helm_chart.empty?
      helm_install = `#{helm} install --namespace hardcoded-ip-test hardcoded-ip-test #{helm_chart} --dry-run --debug > #{destination_cnf_dir}/helm_chart.yml`
      VERBOSE_LOGGING.info "helm_chart: #{helm_chart}" if check_verbose(args)
    else
      helm_install = `#{helm} install --namespace hardcoded-ip-test hardcoded-ip-test #{destination_cnf_dir}/#{helm_directory} --dry-run --debug > #{destination_cnf_dir}/helm_chart.yml`
      VERBOSE_LOGGING.info "helm_directory: #{helm_directory}" if check_verbose(args)
    end

    ip_search = File.read_lines("#{destination_cnf_dir}/helm_chart.yml").take_while{|x| x.match(/NOTES:/) == nil}.reduce([] of String){|acc, x| x.match(/([0-9]{1,3}[\.]){3}[0-9]{1,3}/) && x.match(/([0-9]{1,3}[\.]){3}[0-9]{1,3}/).try &.[0] != "0.0.0.0" ? acc << x : acc}
    VERBOSE_LOGGING.info "IPs: #{ip_search}" if check_verbose(args)

    if ip_search.empty? 
      upsert_passed_task("hardcoded_ip_addresses_in_k8s_runtime_configuration", "✔️  PASSED: No hard-coded IP addresses found in the runtime K8s configuration")
    else
      upsert_failed_task("hardcoded_ip_addresses_in_k8s_runtime_configuration", "✖️  FAILURE: Hard-coded IP addresses found in the runtime K8s configuration")
    end
    delete_namespace = `kubectl delete namespace hardcoded-ip-test --force --grace-period 0 2>&1 >/dev/null`

  end
end
