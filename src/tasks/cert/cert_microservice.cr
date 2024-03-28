# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"
require "docker_client"
require "halite"
require "totem"

desc "The CNF test suite checks to see if CNFs follows microservice principles"
task "cert_microservice", ["cert_microservice_title","reasonable_image_size", "reasonable_startup_time", "single_process_type", "service_discovery", "shared_database", "zombie_handled", "sig_term_handled", "specialized_init_system"] do |_, args|
# task "cert_microservice", ["cert_microservice_title", "reasonable_image_size", "reasonable_startup_time", "service_discovery"] do |_, args|
  # stdout_score("microservice")
  stdout_score(["microservice", "cert"], "microservice")
  case "#{ARGV.join(" ")}" 
  when /cert_microservice/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end

task "cert_microservice_title" do |_, args|
  puts "Microservice Tests".colorize(Colorize::ColorRGB.new(0, 255, 255))
end
