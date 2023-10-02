# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "docker_client"
require "halite"
require "totem"
require "k8s_netstat"
require "kernel_introspection"
require "k8s_kernel_introspection"
require "../utils/utils.cr"

# desc "The CNF test suite checks to see if a 5gCore installed in K8s responds properly"
# task "5gCore", ["supi_enabled"] do |_, args|
#   stdout_score("5g")
#   case "#{ARGV.join(" ")}" 
#   when /5g/
#     stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
#   end
# end
#
# #todo set up a UE and Ran simulator (ueransim) to test the 5g core
# #todo modify ueransime to use supi (5g authenticatio)
# #todo set up tshark to test authentication on the wire
# #todo check the wire using tshark to see if authenticaion worked
#
# desc "To check if the 5g core has supi enabled (5g authentication)"
# task "supi_enabled", [""] do |_, args|
#
# end
#
