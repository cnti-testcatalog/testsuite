require "colorize"
require "kubectl_client"

module ParseKernelInstrospection 
  # todo ls /proc
  def self.parse_ps(ps_output)
    #todo return an array of hashes 
  end

  # todo cat each entry from ls /proc
  def self.parse_status(status_output)
    # todo return a hash
  end
end


module LocalKernelInstrospection
end

module K8sKernelIntrospection
  # todo ls /proc
  def self.ps(container_name)
    KubectlClient.exec("ps")
    #return parse_ps
  end

  # todo cat each entry from ls /proc
  def self.status
    # return parse_status
  end

  def self.status_by_ps
    #todo loop through ps and call kubectl status
  end
end
