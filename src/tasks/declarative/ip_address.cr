require "sam"
require "file_utils"
require "colorize"

CNF_DIR = "cnfs"

desc "Does a search for IP addresses or subnets come back as negative?"
task "addresses" do
	cdir = FileUtils.pwd()
  response = String::Builder.new
  Dir.cd(CNF_DIR)
  Process.run("grep -rnw -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'", shell: true) do |proc|
    # Process.run("grep -rnw -E -o 'hithere'", shell: true) do |proc|
    while line = proc.output.gets
      response << line
      # puts "#{line}"
    end
  end
  if response.to_s.size > 0
    puts "FAILURE: IP addresses found".colorize(:red)
  else
    puts "SUCCESS: No IP addresses found".colorize(:green)
  end
  Dir.cd(cdir)
end

Sam.help
