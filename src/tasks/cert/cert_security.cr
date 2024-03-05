# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "CNF containers should be isolated from one another and the host.  The CNF Test suite uses tools like Sysdig Inspect and gVisor"
task "cert_security", [
   "cert_security_title", 
    "symlink_file_system",
    "privilege_escalation",
    "insecure_capabilities",
    "resource_policies",
    "linux_hardening",
    "ingress_egress_blocked",
    "host_pid_ipc_privileges",
    "non_root_containers",
    "privileged_containers",
    "immutable_file_systems",
    "hostpath_mounts",
    "container_sock_mounts",
    "external_ips",
    "selinux_options",
    "sysctls",
    "host_network",
    "service_account_mapping",
    "application_credentials"
  ] do |_, args|
# task "cert_security", [
#   "cert_security_title", 
#     "symlink_file_system",
#     "privilege_escalation",
#     "insecure_capabilities",
#     "linux_hardening",
#     "ingress_egress_blocked",
#     "host_pid_ipc_privileges",
#     "immutable_file_systems",
#     "hostpath_mounts",
#     "external_ips",
#     "sysctls"
#   ] do |_, args|
  # stdout_score("security")
  stdout_score(["security", "cert"], "security")
  case "#{ARGV.join(" ")}" 
  when /cert_security/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end

task "cert_security_title" do |_, args|
  puts "Security Tests".colorize(Colorize::ColorRGB.new(0, 255, 255))
end
