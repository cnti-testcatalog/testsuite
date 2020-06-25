require "option_parser"

if ARGV.find { |x| x == "setup"}

  OptionParser.parse do |parser|
    parser.banner = "Usage: setup"
    parser.on("-h", "--help", "Show this help") { puts parser }
    parser.invalid_option do |flag|
      STDERR.puts "ERROR #{flag} is not valid"
      STDERR.puts parser
    end
  end

elsif ARGV.find { |x| x == "create_env"}

  env_name = ""
  kubeconfig = ""
  OptionParser.parse do |parser|
    parser.banner = "Usage: create_env [arguments]"
    parser.on("-n NAME", "--name=NAME", "[Required] Specifies the name of the env to create") { |name| env_name = name }
    parser.on("-k FILE", "--kubeconfig=FILE", "[Required] Specifies the path to a kubeconfig") { |file| kubeconfig = file }
    parser.on("-h", "--help", "Show this help") { puts parser }
    parser.invalid_option do |flag|
      STDERR.puts "ERROR #{flag} is not valid"
      STDERR.puts parser
      exit 1
    end
  end
  if env_name.empty? && kubeconfig.empty?
    puts "Required arguments missing [-n, --name] [-k, --kubeconfig]"
  elsif kubeconfig.empty?
    puts "Required argument missing [-k, --kubeconfig]"
  elsif env_name.empty?
    puts "Required argument missing [-n, --name]"
  else
    puts "Creating ENV For: \n Name: #{env_name} \n Kubeconfig: #{kubeconfig}"
    `docker run --name #{env_name} -d -v $(pwd):/cnf-conformance -v #{kubeconfig}:/root/.kube/config -ti cnf-test /bin/sleep infinity`
    puts `docker ps -f name=#{env_name}`
  end


elsif ARGV.find { |x| x == "delete_env"}

  env_name = ""
  OptionParser.parse do |parser|
    parser.banner = "Usage: delete_env [arguments]"
    parser.on("-n NAME", "--name=NAME", "[Required] Specifies the name of the env to delete") { |name| env_name = name }
    parser.on("-h", "--help", "Show this help") { puts parser }
    parser.invalid_option do |flag|
      STDERR.puts "ERROR #{flag} is not valid"
      STDERR.puts parser
      exit 1
    end
  end

  if env_name.empty?
    puts "Required argument missing [-n, --name]"
  else
    puts "Deleteing ENV For: #{env_name}"
    `docker rm -f #{env_name}`
  end


elsif ARGV.find { |x| x == "list_envs"}
    OptionParser.parse do |parser|
      parser.banner = "Usage: list_envs"
      parser.on("-h", "--help", "Show this help") { puts parser }
      parser.invalid_option do |flag|
        STDERR.puts "ERROR #{flag} is not valid"
        STDERR.puts parser
        exit 1
      end
    end

    puts `docker ps -f ancestor=cnf-test --format '{{.Names}}'`

elsif ARGV.find { |x| x == "command"}

  usage = "Usage: command [execute_command]"
  if ARGV[1]? == "--help" || ARGV[1]? == "-h"
     puts "#{usage}"
     exit 0
  end
  execute_command = ARGV[1..-1].join(" ")
  if ENV["CRYSTAL_DEV_ENV"]
    puts "Using Environment: #{ENV["CRYSTAL_DEV_ENV"]}"
    system "docker exec -ti #{ENV["CRYSTAL_DEV_ENV"]} crystal #{execute_command}"
  else
    puts "CRYSTAL_DEV_ENV Not Set. Run list_envs and select one"
  end

else
  puts "Usage: [setup | create_env | delete_env | list_envs | command]"
  OptionParser.parse do |parser|
    parser.on("-h", "--help", "Show this help") { puts parser }
    parser.invalid_option do |flag|
      STDERR.puts "ERROR #{flag} is not valid"
      STDERR.puts parser
    end
  end
end
