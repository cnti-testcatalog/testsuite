require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils.cr"

desc "Configuration and lifecycle should be managed in a declarative manner, using ConfigMaps, Operators, or other declarative interfaces."
task "configuration_lifecycle", ["ip_addresses", "liveness"]  do |_, args|
end

desc "Does a search for IP addresses or subnets come back as negative?"
task "ip_addresses" do |_, args|
	cdir = FileUtils.pwd()
  response = String::Builder.new
  Dir.cd(CNF_DIR)
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
end

#TODO separate out liveness from readiness checks
desc "Is there a liveness entry in the helm chart?"
task "liveness" do |_, args|
  errors = 0
  begin
    helm_directory = CONFIG.get("helm_directory").as_s
  rescue ex
    errors = errors + 1
    puts "FAILURE: helm directory not found".colorize(:red)
    puts ex.message if check_args(args)
  end
  deployment = Totem.from_file "#{helm_directory}/templates/deployment.yaml"
  containers = deployment.get("spec").as_h["template"].as_h["spec"].as_h["containers"].as_a
  containers.each do |container|
    begin
      puts container.as_h["name"].as_s if check_args(args)
      container.as_h["livenessProbe"].as_s 
    rescue ex
      puts ex.message if check_args(args)
      errors = errors + 1
      puts "FAILURE: No livenessProbe found".colorize(:red)
    end
    begin
      puts container.as_h["name"].as_s if check_args(args)
      container.as_h["readinessProbe"].as_s 
    rescue ex
      puts ex.message if check_args(args)
      errors = errors + 1
      puts "FAILURE: No readinessProbe found".colorize(:red)
    end
  end
  if errors == 0
    puts "PASSED: Helm liveness and readiness probes found".colorize(:green)
  end
end
