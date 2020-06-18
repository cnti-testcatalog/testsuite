require "sam"

task "deps" do
  puts "Building Ephemeral_ENV Deps"
  puts `docker build -t cnf-test:latest .`
end

task "create_env" do |_, args|
  puts "Creating ENV For: #{args[0]}"
  `docker run --name #{args[0]} -d -v $(pwd):/cnf-conformance -ti cnf-test /bin/sleep infinity`
  puts `docker ps -f name=#{args[0]}`
end

task "delete_env" do |_, args|
  puts "Deleteing ENV For: #{args[0]}"
  `docker rm -f #{args[0]}`
end


Sam.help
