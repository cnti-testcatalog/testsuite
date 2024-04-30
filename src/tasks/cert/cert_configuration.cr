# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "json"
require "../utils/utils.cr"


desc "Configuration should be managed in a declarative manner, using ConfigMaps, Operators, or other declarative interfaces."

task "cert_configuration" do |t, args|
  puts "Configuration Tests".colorize(Colorize::ColorRGB.new(0, 255, 255))

  essential_only = args.raw.includes? "essential"
  tags = ["configuration", "cert"]
  tags << "essential" if essential_only

  tasks = CNFManager::Points.tasks_by_tag_intersection(tags)
  tasks.each do |task|
    t.invoke(task)
  end

  stdout_score(tags, "configuration")
  case "#{ARGV.join(" ")}" 
  when /cert_configuration/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end
