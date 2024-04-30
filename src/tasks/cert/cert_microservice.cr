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
task "cert_microservice" do |t, args|
  puts "Microservice Tests".colorize(Colorize::ColorRGB.new(0, 255, 255))

  essential_only = args.raw.includes? "essential"
  tags = ["microservice", "cert"]
  tags << "essential" if essential_only

  tasks = CNFManager::Points.tasks_by_tag_intersection(tags)
  tasks.each do |task|
    t.invoke(task)
  end

  stdout_score(tags, "microservice")
  case "#{ARGV.join(" ")}" 
  when /cert_microservice/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end
