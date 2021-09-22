require "log"
module GitClient

  def self.clone(command)
    Log.info { "GitClient.clone command: #{command}" }
    status = Process.run("git clone #{command}",
                         shell: true,
                         output: output = IO::Memory.new,
                         error: stderr = IO::Memory.new)
    Log.info { "GitClient.clone output: #{output.to_s}" }
    Log.info { "GitClient.clone stderr: #{stderr.to_s}" }
    {status: status, output: output, error: stderr}
  end
end
