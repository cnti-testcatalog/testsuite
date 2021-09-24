require "colorize"
require "log"

module Kubescape

  #kubescape scan framework nsa --exclude-namespaces kube-system,kube-public
  def self.scan(cmd="framework nsa --exclude-namespaces kube-system,kube-public")
    alt_cmd = "./tools/kubescape/kubescape scan " + cmd
    Log.info { "command: #{cmd}" }
    status = Process.run(
      alt_cmd,
      shell: true,
      output: output = IO::Memory.new,
      error: stderr = IO::Memory.new
    )
    Log.info { "output: #{output.to_s}" }
    Log.info { "stderr: #{stderr.to_s}" }
    {status: status, output: output.to_s, error: stderr.to_s}
  end

  def self.parse(results)
    #todo parse results, show tests answers by each line
    #todo parse control name, failed resource count
  end

end
