require "sam"
require "file_utils"
require "colorize"
require "totem"
require "json"
require "./utils/utils.cr"

desc "Configuration and lifecycle should be managed in a declarative manner, using ConfigMaps, Operators, or other declarative interfaces."
task "configuration_lifecycle", ["ip_addresses", "liveness", "readiness", "rolling_update", "nodeport_not_used"]  do |_, args|
end

desc "Does a search for IP addresses or subnets come back as negative?"
task "ip_addresses" do |_, args|
  begin
    cdir = FileUtils.pwd()
    response = String::Builder.new
    Dir.cd(CNF_DIR)
    # TODO ignore *example*, *.md, *.txt
    # TODO ignore 0.0.0.0
    Process.run("grep -rnw -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'", shell: true) do |proc|
      # Process.run("grep -rnw -E -o 'hithere'", shell: true) do |proc|
      while line = proc.output.gets
        response << line
        puts "#{line}" if check_args(args)
      end
    end
    Dir.cd(cdir)
    if response.to_s.size > 0
      upsert_failed_task("ip_addresses")
      puts "FAILURE: IP addresses found".colorize(:red)
    else
      upsert_passed_task("ip_addresses")
      puts "PASSED: No IP addresses found".colorize(:green)
    end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end

desc "Is there a liveness entry in the helm chart?"
task "liveness", ["retrieve_manifest"] do |_, args|
  begin
    # Parse the cnf-conformance.yml
    config = cnf_conformance_yml
    errors = 0
    begin
      helm_directory = config.get("helm_directory").as_s
    rescue ex
      errors = errors + 1
      upsert_failed_task("liveness")
      puts "FAILURE: helm directory not found".colorize(:red)
      puts ex.message if check_args(args)
    end
    current_cnf_dir_short_name = cnf_conformance_dir
    puts current_cnf_dir_short_name if check_verbose(args)
    destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    puts destination_cnf_dir if check_verbose(args)
    puts "helm_directory: #{destination_cnf_dir}/#{helm_directory}/manifest.yml" if check_verbose(args)
    deployment = Totem.from_file "#{destination_cnf_dir}/#{helm_directory}/manifest.yml"
    puts deployment.inspect if check_verbose(args)
    containers = deployment.get("spec").as_h["template"].as_h["spec"].as_h["containers"].as_a
    containers.each do |container|
      begin
        puts container.as_h["name"].as_s if check_args(args)
        container.as_h["livenessProbe"].as_h 
      rescue ex
        puts ex.message if check_args(args)
        errors = errors + 1
        upsert_failed_task("liveness")
        puts "FAILURE: No livenessProbe found".colorize(:red)
      end
    end
    if errors == 0
      upsert_passed_task("liveness")
      puts "PASSED: Helm liveness probe found".colorize(:green)
    end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end

desc "Is there a readiness entry in the helm chart?"
task "readiness", ["retrieve_manifest"] do |_, args|
  begin
    # Parse the cnf-conformance.yml
    config = cnf_conformance_yml
    errors = 0
    begin
      helm_directory = config.get("helm_directory").as_s
    rescue ex
      errors = errors + 1
      upsert_failed_task("readiness")
      puts "FAILURE: helm directory not found".colorize(:red)
      puts ex.message if check_args(args)
    end
    current_cnf_dir_short_name = cnf_conformance_dir
    puts current_cnf_dir_short_name if check_verbose(args)
    destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    puts destination_cnf_dir if check_verbose(args)
    puts "helm_directory: #{destination_cnf_dir}/#{helm_directory}/manifest.yml" if check_verbose(args)
    deployment = Totem.from_file "#{destination_cnf_dir}/#{helm_directory}/manifest.yml"
    puts deployment.inspect if check_verbose(args)
    containers = deployment.get("spec").as_h["template"].as_h["spec"].as_h["containers"].as_a
    containers.each do |container|
     begin
        puts container.as_h["name"].as_s if check_args(args)
        container.as_h["readinessProbe"].as_h 
      rescue ex
        puts ex.message if check_args(args)
        errors = errors + 1
        upsert_failed_task("readiness")
        puts "FAILURE: No readinessProbe found".colorize(:red)
      end
    end
    if errors == 0
      upsert_passed_task("readiness")
      puts "PASSED: Helm readiness probe found".colorize(:green)
    end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end

desc "Retrieve the manifest for the CNF's helm chart"
task "retrieve_manifest" do |_, args| 
  begin
    puts "retrieve_manifest" if check_verbose(args)
    config = cnf_conformance_yml
    deployment_name = config.get("deployment_name").as_s
    service_name = config.get("service_name").as_s
    puts deployment_name if check_verbose(args)
    puts service_name if check_verbose(args)
    helm_directory = config.get("helm_directory").as_s
    puts helm_directory if check_verbose(args)
    current_cnf_dir_short_name = cnf_conformance_dir
    puts current_cnf_dir_short_name if check_verbose(args)
    destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    puts destination_cnf_dir if check_verbose(args)
    deployment = `kubectl get deployment #{deployment_name} -o yaml  > #{destination_cnf_dir}/#{helm_directory}/manifest.yml`
    puts deployment if check_verbose(args)
    service = `kubectl get service #{service_name} -o yaml  > #{destination_cnf_dir}/service.yml`
    puts service if check_verbose(args)


  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end

desc "Test if the CNF can perform a rolling update"
task "rolling_update" do |_, args|
  begin
    puts "rolling_update" if check_verbose(args)
    config = cnf_conformance_yml

    version_tag = nil

    if config.has_key? "rolling_update_tag"
      version_tag = config.get("rolling_update_tag").as_s
    end

    if args.named.has_key? "version_tag"
      version_tag = args.named["version_tag"]
    end
    
    unless version_tag
      upsert_failed_task("rolling_update")
      raise "FAILURE: please specify a version of the CNF's release's image with the option version_tag or with cnf_conformance_yml option 'rolling_update_tag'"
    end

    release_name = config.get("release_name").as_s
    deployment_name = config.get("deployment_name").as_s

    helm_chart_values = JSON.parse(`#{tools_helm} get values #{release_name} -a --output json`)
    puts "helm_chart_values" if check_verbose(args)
    puts helm_chart_values if check_verbose(args)
    image_name = helm_chart_values["image"]["repository"]

    puts "image_name: #{image_name}" if check_verbose(args)

    puts "rolling_update: setting new version" if check_verbose(args)
    #do_update = `kubectl set image deployment/coredns-coredns coredns=coredns/coredns:latest --record`
    puts "kubectl set image deployment/#{deployment_name} #{release_name}=#{image_name}:#{version_tag} --record" if check_verbose(args)
    do_update = `kubectl set image deployment/#{deployment_name} #{release_name}=#{image_name}:#{version_tag} --record`

    # https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#rolling-update
    puts "rolling_update: checking status new version" if check_verbose(args)
    puts `kubectl rollout status deployment/#{deployment_name} --timeout=30s`

    if $?.success?
      upsert_passed_task("rolling_update")
      puts "PASSED: CNF #{deployment_name} Rolling Update Passed".colorize(:green)
    else
      upsert_failed_task("rolling_update")
      puts "FAILURE: CNF #{deployment_name} Rolling Update Failed".colorize(:red)
    end

  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end

desc "Does the CNF use NodePort"
task "nodeport_not_used", ["retrieve_manifest"] do |_, args|
  begin
    puts "nodeport_not_used" if check_verbose(args)
    config = cnf_conformance_yml
    release_name = config.get("release_name").as_s
    service_name = config.get("service_name").as_s
    current_cnf_dir_short_name = cnf_conformance_dir
    puts current_cnf_dir_short_name if check_verbose(args)
    destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)

    service = Totem.from_file "#{destination_cnf_dir}/service.yml"
    puts service.inspect if check_verbose(args)
    service_type = service.get("spec").as_h["type"].as_s
    puts service_type if check_verbose(args)
    if service_type == "NodePort" 
      puts "FAILURE: NodePort is being used".colorize(:red)
      upsert_failed_task("nodeport_not_used")
    else
      puts "PASSED: NodePort is not used"
      upsert_passed_task("nodeport_not_used").colorize(:green)
    end

  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end

desc "Does the CNF have hardcoded IPs in the K8s resource configuration"
task "hardcoded_ip_addresses_in_k8s_runtime_configuration", ["retrieve_manifest"] do |_, args|
  begin
    puts "hardcoded_ip_addresses_in_k8s_runtime_configuration" if check_verbose(args)
    config = cnf_conformance_yml
    release_name = config.get("release_name").as_s
    deployment_name = config.get("service_name").as_s
    helm_directory = config.get("helm_directory").as_s
    current_cnf_dir_short_name = cnf_conformance_dir
    puts current_cnf_dir_short_name if check_verbose(args)
    destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)

    deployment = Totem.from_file "#{destination_cnf_dir}/#{helm_directory}/manifest.yml"
    puts deployment.inspect if check_verbose(args)

    # Fetch an array of configmaps attatched to the CNF
    volumes = deployment.get("spec").as_h["template"].as_h["spec"].as_h["volumes"].as_a
    puts volumes.inspect if check_verbose(args)
    config_maps = [] of Array(Hash(Int32, String))
    config_maps = volumes.map do |configmap|
      configmap.as_h["configMap"]["name"]
    end
    puts "configmap_names: #{config_maps.inspect}" if check_verbose(args)

    # Pull down the manifest for each configmap and return and array of file names"
    fetch_configmaps = config_maps.map do |configmap_name| 
      `kubectl get configmaps #{configmap_name} -o yaml  > #{destination_cnf_dir}/configmap_#{configmap_name}.yml`
      "configmap_#{configmap_name}.yml"
    end
    puts "configmap_yml_files: #{fetch_configmaps}" if check_verbose(args)

    # Parse all configmap manifest files and check for hardcoded IPs
    configmap_hardcoded_ip_search = fetch_configmaps.reduce([] of String) do |acc, configmap_file | 
      grep = `grep -rnw -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}' #{destination_cnf_dir}/#{configmap_file}`
      unless grep.empty? 
        acc = acc << "#{configmap_file}: #{grep}"
      else
        acc
      end
    end
    puts "configmap ip search: #{configmap_hardcoded_ip_search}" if check_verbose(args)



  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end
