# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "../utils/utils.cr"

desc "The CNF test suite checks to see if the CNFs are resilient to failures."
 task "cert_resilience" do |t, args|
  puts "Reliability, Resilience, and Availability Tests".colorize(Colorize::ColorRGB.new(0, 255, 255))

  essential_only = args.raw.includes? "essential"
  tags = ["resilience", "cert"]
  tags << "essential" if essential_only

  tasks = CNFManager::Points.tasks_by_tag_intersection(tags)
  tasks.each do |task|
    t.invoke(task)
  end

  Log.for("verbose").info {  "resilience" } if check_verbose(args)
  VERBOSE_LOGGING.debug "resilience args.raw: #{args.raw}" if check_verbose(args)
  VERBOSE_LOGGING.debug "resilience args.named: #{args.named}" if check_verbose(args)
  stdout_score(tags, "Reliability, Resilience, and Availability")
  case "#{ARGV.join(" ")}" 
  when /cert_resilience/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end
