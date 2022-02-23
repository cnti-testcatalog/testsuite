require "log"

module ShellCmd
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
    Log.info { "#{log_prefix} stderr: #{stderr.to_s}" }
    {status: status, output: output.to_s, error: stderr.to_s}
  end
end

# ShellCmd.run("./cnf-testsuite setup", "testsuite-setup", force_output: true)

ShellCmd.run("kubectl version", "testsuite-setup", force_output: true)