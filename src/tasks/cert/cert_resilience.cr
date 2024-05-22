# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "../utils/utils.cr"
require "./cert_utils.cr"

desc "The CNF test suite checks to see if the CNFs are resilient to failures."
 task "cert_resilience" do |t, args|
  puts "Reliability, Resilience, and Availability Tests".colorize(Colorize::ColorRGB.new(0, 255, 255))

  exclude = get_excluded_tasks(args)
  essential_only = args.raw.includes? "essential"
  tags = ["resilience", "cert"]
  tags << "essential" if essential_only

  invoke_tasks_by_tag_list(t, tags, exclude_tasks: exclude)

  Log.for("verbose").info {  "resilience" } if check_verbose(args)
  VERBOSE_LOGGING.debug "resilience args.raw: #{args.raw}" if check_verbose(args)
  VERBOSE_LOGGING.debug "resilience args.named: #{args.named}" if check_verbose(args)
  cert_stdout_score(tags, "Reliability, Resilience, and Availability", exclude_warning: !exclude.empty?)
  case "#{ARGV.join(" ")}" 
  when /cert_resilience/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end
