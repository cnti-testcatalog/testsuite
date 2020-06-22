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

# task "list_envs"

# task "select_env"

task "delete_env" do |_, args|
  puts "Deleteing ENV For: #{args[0]}"
  `docker rm -f #{args[0]}`
end

task "command" do |_, args|
  command_args = ARGV[1..-1].join(" ")
  puts "Args: #{command_args}"
  system "docker exec -ti test2 crystal #{args[0]}"
end
Sam.help
