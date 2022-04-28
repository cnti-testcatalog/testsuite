# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"
# require "../utils/docker_client.cr"
require "docker_client"
require "halite"
require "totem"

desc "The CNF test suite checks to see if CNFs follows microservice principles"
task "cert_microservice", ["cert_microservice_title", "reasonable_image_size", "reasonable_startup_time", "service_discovery"] do |_, args|
  stdout_score("microservice")
end

task "cert_microservice_title" do |_, args|
  puts "Microservice Tests".colorize(Colorize::ColorRGB.new(0, 255, 255))
end
