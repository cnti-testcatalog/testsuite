# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"
require "kubectl_client"

desc "The CNF test suite checks if state is stored in a custom resource definition or a separate database (e.g. etcd) rather than requiring local storage.  It also checks to see if state is resilient to node failure"
task "cert_state" do |t, args|
  puts "State Tests".colorize(Colorize::ColorRGB.new(0, 255, 255))

  essential_only = args.raw.includes? "essential"
  tags = ["state", "cert"]
  tags << "essential" if essential_only

  tasks = CNFManager::Points.tasks_by_tag_intersection(tags)
  tasks.each do |task|
    t.invoke(task)
  end

  stdout_score(tags, "state")
  case "#{ARGV.join(" ")}" 
  when /cert_state/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end
