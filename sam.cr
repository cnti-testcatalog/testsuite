require "sam"

# Here you can define your tasks
# desc "with description to be used by help command"
task "test" do
  puts "ping"
end

Sam.help
