require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils.cr"

desc "Configuration and lifecycle should be managed in a declarative manner, using ConfigMaps, Operators, or other declarative interfaces."
task "configuration_lifecycle", ["ip_addresses", "liveness", "readiness"]  do |_, args|
end

desc "Does a search for IP addresses or subnets come back as negative?"
task "ip_addresses" do |_, args|
  begin
    cdir = FileUtils.pwd()
    response = String::Builder.new
    Dir.cd(CNF_DIR)
    # TODO ignore *example*, *.md, *.txt
    Process.run("grep -rnw -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'", shell: true) do |proc|
      # Process.run("grep -rnw -E -o 'hithere'", shell: true) do |proc|
      while line = proc.output.gets
        response << line
        puts "#{line}" if check_args(args)
      end
    end
    if response.to_s.size > 0
      puts "FAILURE: IP addresses found".colorize(:red)
    else
      puts "PASSED: No IP addresses found".colorize(:green)
    end
    Dir.cd(cdir)
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end

#TODO separate out liveness from readiness checks
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
        puts "FAILURE: No livenessProbe found".colorize(:red)
      end
    end
    if errors == 0
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
        puts "FAILURE: No readinessProbe found".colorize(:red)
      end
    end
    if errors == 0
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
    puts deployment_name if check_verbose(args)
    helm_directory = config.get("helm_directory").as_s
    puts helm_directory if check_verbose(args)
    current_cnf_dir_short_name = cnf_conformance_dir
    puts current_cnf_dir_short_name if check_verbose(args)
    destination_cnf_dir = sample_destination_dir(current_cnf_dir_short_name)
    puts destination_cnf_dir if check_verbose(args)
    manifest = `kubectl get deployment #{deployment_name} -o yaml  > #{destination_cnf_dir}/#{helm_directory}/manifest.yml`
    puts manifest if check_verbose(args)
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end
