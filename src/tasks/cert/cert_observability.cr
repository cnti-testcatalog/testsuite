# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "In order to maintain, debug, and have insight into a protected environment, its infrastructure elements must have the property of being observable. This means these elements must externalize their internal states in some way that lends itself to metrics, tracing, and logging."
task "cert_observability" do |t, args|
  puts "Observability and Diagnostics Tests".colorize(Colorize::ColorRGB.new(0, 255, 255))

  essential_only = args.raw.includes? "essential"
  tags = ["observability", "cert"]
  tags << "essential" if essential_only

  tasks = CNFManager::Points.tasks_by_tag_intersection(tags)
  tasks.each do |task|
    t.invoke(task)
  end

  stdout_score(tags, "Observability and Diagnostics")
  case "#{ARGV.join(" ")}" 
  when /cert_observability/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end
