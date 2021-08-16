require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"

module Falco

  def self.find_root_pod(pod_name)
    LOGGING.info "Falco.find_root_pod: #{pod_name}"
    resp = KubectlClient.logs(pod_name)
    output = resp[:output]
    match = output.to_s.match(/.*root.*\(k8s_pod=#{pod_name}\)/) 
    if match
      true
    else
      false
    end
  end
end
