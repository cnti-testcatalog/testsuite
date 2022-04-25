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
task "cert_microservice", ["reasonable_image_size", "reasonable_startup_time", "service_discovery"] do |_, args|
  stdout_score("microservice")
end

