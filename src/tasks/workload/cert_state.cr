# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"
require "kubectl_client"

desc "The CNF test suite checks if state is stored in a custom resource definition or a separate database (e.g. etcd) rather than requiring local storage.  It also checks to see if state is resilient to node failure"
task "cert_state", ["volume_hostpath_not_found", "no_local_volume_configuration", "elastic_volumes", "database_persistence"] do |_, args|
  stdout_score("state")
end

