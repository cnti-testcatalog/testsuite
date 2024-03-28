# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"
require "kubectl_client"

desc "The CNF test suite checks if state is stored in a custom resource definition or a separate database (e.g. etcd) rather than requiring local storage.  It also checks to see if state is resilient to node failure"
task "cert_state", ["cert_state_title", "no_local_volume_configuration", "elastic_volumes", "node_drain", "volume_hostpath_not_found"] do |_, args|
# task "cert_state", ["cert_state_title", "no_local_volume_configuration", "elastic_volumes" ] do |_, args|
  # stdout_score("state")
  stdout_score(["state", "cert"], "state")
  case "#{ARGV.join(" ")}" 
  when /cert_state/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end

task "cert_state_title" do |_, args|
  puts "State Tests".colorize(Colorize::ColorRGB.new(0, 255, 255))
end

