require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils.cr"

desc "Does the install script use helm?"
task "install_script_helm" do |_, args|
  found = 0
  install_script = CONFIG.get("install_script").as_s
  response = String::Builder.new
  content = File.open(install_script) do |file|
    file.gets_to_end
  end
  # puts content
  if /helm/ =~ content 
    found = 1
  end
  if found < 1
    puts "FAILURE: Helm not found in install script".colorize(:red)
  else
    puts "PASSED: Helm found in install script".colorize(:green)
  end
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
