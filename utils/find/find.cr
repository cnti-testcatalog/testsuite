require "colorize"
require "log"

module Find 
  def self.find(directory, wildcard="*.tar*", maxdepth="1", silent=true)
    Log.info { "find command: find #{directory} -maxdepth #{maxdepth} -name #{wildcard}" }
    status = Process.run("find #{directory} -maxdepth #{maxdepth} -name \"#{wildcard}\"",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    Log.info { "find output: #{output.to_s}" }
    Log.info { "find stderr: #{stderr.to_s}" }
    found_files = output.to_s.split("\n").select{|x| x.empty? == false}
    if found_files.size == 0 && !silent
      raise "No files found!"
    end
    found_files
  end
end
