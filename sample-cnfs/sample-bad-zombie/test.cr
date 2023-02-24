require "log"

module ShellCmd
    def self.new(cmd, log_prefix, force_output=false)
      Log.info { "#{log_prefix} command: #{cmd}" }
      process = Process.new(
        cmd,
        shell: true,
        output: output = IO::Memory.new,
        error: stderr = IO::Memory.new
      )
      if force_output == false
        Log.debug { "#{log_prefix} output: #{output.to_s}" }
      else
        Log.info { "#{log_prefix} output: #{output.to_s}" }
      end

      # Don't have to output log line if stderr is empty
      if stderr.to_s.size > 1
        Log.info { "#{log_prefix} stderr: #{stderr.to_s}" }
      end
      {process: process, output: output.to_s, error: stderr.to_s}
    end

    def self.run(cmd, log_prefix, force_output=false)
      Log.info { "#{log_prefix} command: #{cmd}" }
      status = Process.run(
        cmd,
        shell: true,
        output: output = IO::Memory.new,
        error: stderr = IO::Memory.new
      )
      if force_output == false
        Log.debug { "#{log_prefix} output: #{output.to_s}" }
      else
        Log.info { "#{log_prefix} output: #{output.to_s}" }
      end

      # Don't have to output log line if stderr is empty
      if stderr.to_s.size > 1
        Log.info { "#{log_prefix} stderr: #{stderr.to_s}" }
      end
      {status: status, output: output.to_s, error: stderr.to_s}
    end
  end
  
  ShellCmd.run("/zombie", "zombie", false)
#  ShellCmd.run("sleep 100000", "sleep", false)
