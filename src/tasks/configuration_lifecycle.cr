# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "json"
require "./utils/utils.cr"

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
    errors = 0
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    deployment = Totem.from_file "#{destination_cnf_dir}/manifest.yml"
    VERBOSE_LOGGING.debug deployment.inspect if check_verbose(args)
    emoji_probe="🧫"
    containers = deployment.get("spec").as_h["template"].as_h["spec"].as_h["containers"].as_a
    containers.each do |container|
      begin
        VERBOSE_LOGGING.debug container.as_h["name"].as_s if check_verbose(args)
        container.as_h["livenessProbe"].as_h 
      rescue ex
        VERBOSE_LOGGING.error ex.message if check_verbose(args)
        errors = errors + 1
        resp = upsert_failed_task("liveness","✖️  FAILURE: No livenessProbe found #{emoji_probe}")
      end
    end
    if errors == 0
      resp = upsert_passed_task("liveness","✔️  PASSED: Helm liveness probe found #{emoji_probe}")
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
  task_runner(args) do |args|
    VERBOSE_LOGGING.info "retrieve_manifest" if check_verbose(args)
    # config = cnf_conformance_yml
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    deployment_name = config.get("deployment_name").as_s
    service_name = config.get("service_name").as_s
    VERBOSE_LOGGING.debug "Deployment_name: #{deployment_name}" if check_verbose(args)
    VERBOSE_LOGGING.debug service_name if check_verbose(args)
    helm_directory = config.get("helm_directory").as_s
    VERBOSE_LOGGING.debug helm_directory if check_verbose(args)
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    deployment = `kubectl get deployment #{deployment_name} -o yaml  > #{destination_cnf_dir}/manifest.yml`
    VERBOSE_LOGGING.debug deployment if check_verbose(args)
    unless service_name.empty?
      service = `kubectl get service #{service_name} -o yaml  > #{destination_cnf_dir}/service.yml`
    end
    VERBOSE_LOGGING.debug service if check_verbose(args)
    service
  end
end

def get_helm_chart_values(sam_args, release_name)
  # helm_chart_values = JSON.parse(`#{CNFManager.local_helm_path} get values #{release_name} -a --output json`)
  LOGGING.info "helm path: #{CNFSingleton.helm}"
  LOGGING.info "helm command: #{CNFSingleton.helm} get values #{release_name} -a --output json"
  helm_resp = `#{CNFSingleton.helm} get values #{release_name} -a --output json`
  # helm sometimes does not return valid json :/
  helm_split = helm_resp.split("\n")
  LOGGING.info "helm_split: #{helm_split}"
  if helm_split[1] =~ /WARNING/ 
    cleaned_resp = helm_split[2] 
  elsif helm_split[0] =~ /WARNING/
    cleaned_resp = helm_split[1] 
  else
    cleaned_resp = helm_split[0]
  end
  LOGGING.info "cleaned_resp: #{cleaned_resp}"
  helm_chart_values = JSON.parse(cleaned_resp)
  VERBOSE_LOGGING.debug "helm_chart_values" if check_verbose(sam_args)
  VERBOSE_LOGGING.debug helm_chart_values if check_verbose(sam_args)
  helm_chart_values
end
test_names = ["rolling_update", "rolling_downgrade", "rolling_version_change"]

test_names.each do |tn|
  pretty_test_name = tn.split(/:|_/).join(" ")
  pretty_test_name_capitalized = tn.split(/:|_/).map(&.capitalize).join(" ")

  desc "Test if the CNF can perform a #{pretty_test_name}"
  task "#{tn}" do |_, args|
    task_runner(args) do |args|
      VERBOSE_LOGGING.info tn if check_verbose(args)
      # config = cnf_conformance_yml
      config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))

      version_tag = nil

      if config.has_key? "#{tn}_tag"
        version_tag = config.get("#{tn}_tag").as_s
      end

      if args.named.has_key? "version_tag"
        version_tag = args.named["version_tag"]
      end
      
      unless version_tag
        fail_msg = "✖️  FAILURE: please specify a version of the CNF's release's image with the cli option version_tag or with cnf_conformance_yml option '#{tn}_tag'"
        upsert_failed_task(tn, fail_msg)
        raise fail_msg
      end

      release_name = config.get("release_name").as_s
      deployment_name = config.get("deployment_name").as_s
      helm_chart_container_name = config.get("helm_chart_container_name").as_s

      helm_chart_values = get_helm_chart_values(args, release_name)
      image_name = helm_chart_values["image"]["repository"]

      VERBOSE_LOGGING.debug "image_name: #{image_name}" if check_verbose(args)

      VERBOSE_LOGGING.debug "#{tn} setting new version" if check_verbose(args)
      #do_update = `kubectl set image deployment/coredns-coredns coredns=coredns/coredns:latest --record`
      VERBOSE_LOGGING.debug "kubectl set image deployment/#{deployment_name} #{helm_chart_container_name}=#{image_name}:#{version_tag} --record" if check_verbose(args)
      version_change = `kubectl set image deployment/#{deployment_name} #{helm_chart_container_name}=#{image_name}:#{version_tag} --record`
      version_change_applied = $?.success?
      VERBOSE_LOGGING.debug "#{version_change}" if check_verbose(args)
      VERBOSE_LOGGING.debug "change successful? #{version_change_applied}" if check_verbose(args)

      # https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#rolling-update
      VERBOSE_LOGGING.debug "#{tn}: checking status new version" if check_verbose(args)
      rollout = `kubectl rollout status deployment/#{deployment_name} --timeout=30s`
      rollout_status = $?.success?
      VERBOSE_LOGGING.debug "#{rollout}" if check_verbose(args)
      VERBOSE_LOGGING.debug "rollout? #{rollout_status}" if check_verbose(args)
      if version_change_applied && rollout_status
        upsert_passed_task(tn,"✔️  PASSED: CNF #{deployment_name} #{pretty_test_name_capitalized} Passed" )
      else
        upsert_failed_task(tn, "✖️  FAILURE: CNF #{deployment_name} #{pretty_test_name_capitalized} Failed")
      end
    end
  end
  
end

desc "Test if the CNF can perform a rollback"
task "rollback" do |_, args|
  task_runner(args) do |args|
    VERBOSE_LOGGING.info "rollback" if check_verbose(args)
    # config = cnf_conformance_yml
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))

    VERBOSE_LOGGING.debug "actual configin it #{config.inspect}" if check_verbose(args)

    rollback_from_tag = nil

    if config.has_key? "rollback_from_tag"
      rollback_from_tag = config.get("rollback_from_tag").as_s
    end

    if args.named.has_key? "rollback_from_tag"
      rollback_from_tag = args.named["rollback_from_tag"]
    end
    
    unless rollback_from_tag
      fail_msg = "✖️  FAILURE: please specify a version of the CNF's release's image with the cli option rollback_from_tag or with cnf_conformance_yml option 'rollback_from_tag'"
      upsert_failed_task("rollback", fail_msg)
      raise fail_msg
    end

    release_name = config.get("release_name").as_s
    deployment_name = config.get("deployment_name").as_s
    helm_chart_container_name = config.get("helm_chart_container_name").as_s

    helm_chart_values = get_helm_chart_values(args, release_name)
    image_name = helm_chart_values["image"]["repository"]
    image_tag = helm_chart_values["image"]["tag"]

    if rollback_from_tag == image_tag
      fail_msg = "✖️  FAILURE: please specify a different version than the helm chart default image.tag for 'rollback_from_tag' "
      upsert_failed_task("rollback", fail_msg)
      raise fail_msg
    end

    VERBOSE_LOGGING.debug "image_name: #{image_name}" if check_verbose(args)

    VERBOSE_LOGGING.debug "rollback: setting new version" if check_verbose(args)
    #do_update = `kubectl set image deployment/coredns-coredns coredns=coredns/coredns:latest --record`
    VERBOSE_LOGGING.debug "kubectl set image deployment/#{deployment_name} #{helm_chart_container_name}=#{image_name}:#{rollback_from_tag} --record" if check_verbose(args)
    version_change = `kubectl set image deployment/#{deployment_name} #{helm_chart_container_name}=#{image_name}:#{rollback_from_tag} --record`
    version_change_applied = $?.success?
    VERBOSE_LOGGING.debug "#{version_change}" if check_verbose(args)
    VERBOSE_LOGGING.debug "change successful? #{version_change_applied}" if check_verbose(args)

    VERBOSE_LOGGING.debug "rollback: checking status new version" if check_verbose(args)
    rollout = `kubectl rollout status deployment/#{deployment_name} --timeout=30s`
    rollout_status = $?.success?
    VERBOSE_LOGGING.debug "#{rollout}" if check_verbose(args)
    VERBOSE_LOGGING.debug "rollout? #{rollout_status}" if check_verbose(args)
    

    # https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-to-a-previous-revision
    VERBOSE_LOGGING.debug "rollback: rolling back to old version" if check_verbose(args)
    rollback = `kubectl rollout undo deployment/#{deployment_name}`
    rollback_status = $?.success?
    VERBOSE_LOGGING.debug "rollback: #{rollback}" if check_verbose(args)
    VERBOSE_LOGGING.debug "rollout status? #{rollback_status}" if check_verbose(args)


    if version_change_applied && rollout_status && rollback_status
      upsert_passed_task("rollback","✔️  PASSED: CNF #{deployment_name} Rollback Passed" )
    else
      upsert_failed_task("rollback", "✖️  FAILURE: CNF #{deployment_name} Rollback Failed")
    end
  end
end

desc "Does the CNF use NodePort"
task "nodeport_not_used", ["retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "nodeport_not_used" if check_verbose(args)
    # config = cnf_conformance_yml
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    release_name = config.get("release_name").as_s
    service_name = config.get("service_name").as_s
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
