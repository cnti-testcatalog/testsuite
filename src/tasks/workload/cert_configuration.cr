# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "json"
require "../utils/utils.cr"


desc "Configuration should be managed in a declarative manner, using ConfigMaps, Operators, or other declarative interfaces."

task "cert_configuration", [
    "cert_configuration_title",
    "ip_addresses",
    "nodeport_not_used",
    "secrets_used",
    "immutable_configmap",
    "alpha_k8s_apis",
    "require_labels",
    "default_namespace"
  ] do |_, args|
  stdout_score("configuration", "configuration")
end

task "cert_configuration_title" do |_, args|
  puts "Configuration Tests".colorize(:green)
end
