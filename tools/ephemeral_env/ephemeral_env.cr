require "sam"

task "setup" do
  puts "Setting up Ephemeral ENV"
  puts `docker build -t cnf-test:latest $(pwd)/tools/ephemeral_env/`
  puts "alias crystal='crystal $(pwd)/tools/ephemeral_env/ephemeral_env.cr command -- $@'"
end

task "create_env" do |_, args|
  puts "Creating ENV For: name: #{args[0]} kubeconfig: #{args[1]}"
  `docker run --name #{args[0]} -d -v $(pwd):/cnf-conformance -v #{args[1]}:/root/.kube/config -ti cnf-test /bin/sleep infinity`
  puts `docker ps -f name=#{args[0]}`
  `export $PATH`
end

task "list_envs" do
  puts `docker ps -f ancestor=cnf-test --format '{{.Names}}'`
end

task "delete_env" do |_, args|
  puts "Deleteing ENV For: #{args[0]}"
  `docker rm -f #{args[0]}`
end

task "command" do |_, args|
  command_args = ARGV[1..-1].join(" ")
  if ENV["CRYSTAL_DEV_ENV"]
    puts "Using Crystal ENV: #{ENV["CRYSTAL_DEV_ENV"]}"
    puts "Args: #{command_args}"
    system "docker exec -ti #{ENV["CRYSTAL_DEV_ENV"]} crystal #{command_args}"
  else
    puts "CRYSTAL_DEV_ENV Not Set. Run list_envs"
  end
end
Sam.help
