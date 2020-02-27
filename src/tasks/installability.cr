require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils.cr"

desc "The CNF conformance suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s kubectl"
task "installability", ["install_script_helm", "helm_chard_valid"] do |_, args|
end

desc "Does the install script use helm?"
task "install_script_helm" do |_, args|
  begin
    # Parse the cnf-conformance.yml
    config = cnf_conformance_yml

    found = 0
    install_script = config.get("install_script").as_s
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
  rescue ex
    puts ex.message
  end
end

task "helm_chard_valid" do |_, args|
  begin
    puts "increase_capacity args.raw: #{args.raw}" if check_verbose(args)
    puts "increase_capacity args.named: #{args.named}" if check_verbose(args)

    response = String::Builder.new

    config = cnf_conformance_yml
    helm_directory = config.get("helm_directory").as_s
    helm_chart_repo = config.get("helm_chart").as_s

    if args.named.keys.includes? "cnf_chart_path"
      helm_directory = args.named["cnf_chart_path"]
    end

    puts "helm_directory: #{helm_directory}" if check_verbose(args)

    Process.run("helm lint #{helm_directory}", shell: true) do |proc|
      while line = proc.output.gets
        response << line
        puts "#{line}" if check_args(args)
      end
    end

   if $?.success? 
     puts "PASSED: Helm Chart #{helm_chart_repo} Lint Passed".colorize(:green)
   else
     puts "FAILURE: Helm Chart #{helm_chart_repo} Lint Failed".colorize(:red)
   end
  # rescue ex
    # puts ex.message
  end
end
