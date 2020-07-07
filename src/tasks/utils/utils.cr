require "totem"
require "colorize"
require "./sample_utils.cr"
require "logger"
require "file_utils"
require "option_parser"

# TODO make constants local or always retrieve from environment variables
# TODO Move constants out
# TODO put these functions into a module

CNF_DIR = "cnfs"
CONFIG_FILE = "cnf-conformance.yml"
TOOLS_DIR = "tools"
BASE_CONFIG = "./config.yml"
# Results.file = "cnf-conformance-results-#{Time.utc.to_s("%Y%m%d")}.log"
# Results.file = "results.yml"
POINTSFILE = "points.yml"
PASSED = "passed"
FAILED = "failed"
DEFAULT_POINTSFILENAME = "points_v1.yml"
PRIVILEGED_WHITELIST_CONTAINERS = ["chaos-daemon"]

class LogLevel
  class_property command_line_loglevel : String = ""
end

OptionParser.parse do |parser|
  parser.banner = "Usage: cnf-conformance [arguments]"
  parser.on("-l LEVEL", "--loglevel=LEVEL", "Specifies the logging level for cnf-conformance suite") { |level| LogLevel.command_line_loglevel = level }
  parser.on("-h", "--help", "Show this help") { puts parser }
end

#TODO switch to ERROR for production builds
# LOGGING = Logger.new(STDOUT, Logger::ERROR)
LOGGING = Logger.new(STDOUT, Logger::INFO)
LOGGING.progname = "cnf-conformance"
LOGGING.level=loglevel

LOGGING.formatter = Logger::Formatter.new do |severity, datetime, progname, message, io|
	label = severity.unknown? ? "ANY" : severity.to_s
	io << label[0] << ", [" << datetime << " #" << Process.pid << "] "
	io << label.rjust(5) << " -- " << progname << ": " << message
end

def loglevel
  levelstr = "" # default to unset

  # of course last setting wins so make sure to keep the precendence order desired
  # currently
  # 
  # 1. Cli flag is highest precedence
  # 2. Environment var is next level of precedence
  # 3. Config file is last level of precedence

  # lowest priority is first
  if File.exists?(BASE_CONFIG)
    config = Totem.from_file BASE_CONFIG 
    if config["loglevel"].as_s?
      levelstr = config["loglevel"].as_s
    end
  end

  if ENV.has_key?("LOGLEVEL") 
    levelstr = ENV["LOGLEVEL"]
  end

  # highest priority is last
  if !LogLevel.command_line_loglevel.empty?
    levelstr = LogLevel.command_line_loglevel
  end

  if Logger::Severity.parse?(levelstr)
    Logger::Severity.parse(levelstr)
  else
    if !levelstr.empty?
      LOGGING.error "Invalid logging level set. defaulting to ERROR"
    end
    # if nothing set but also nothing missplled then silently default to error
    Logger::ERROR
  end
end

class Results
  @@file : String
  @@file = create_final_results_yml_name
  LOGGING.info "Results file"
  continue = false
  LOGGING.info "file exists?:#{File.exists?(@@file)}"
  if File.exists?("#{@@file}")
    stdout_info "Do you wish to overwrite the #{@@file} file? If so, your previous results.yml will be lost."
    print "(Y/N) (Default N): > "
    if ENV["CRYSTAL_ENV"]? == "TEST"
      continue = true
    else
      user_input = gets
      if user_input == "Y" || user_input == "y"
        continue = true
      end
    end
  else
    continue = true
  end
  if continue
    File.open("#{@@file}", "w") do |f|
      YAML.dump(template_results_yml, f)
    end
  end
  def self.file
    @@file
  end
end

def check_verbose(args)
  if ((args.raw.includes? "verbose") || (args.raw.includes? "v") || (LOGGING.info?) ) 
    true
  else 
    false
  end
end

def check_cnf_config(args)
  LOGGING.debug "args = #{args.inspect}" if check_verbose(args)
  LOGGING.info("check_cnf_config args: #{args.inspect}")
  if args.named.keys.includes? "cnf-config"
    yml_file = args.named["cnf-config"].as(String)
    cnf = File.dirname(yml_file)
    LOGGING.info "all cnf: #{cnf}" if check_verbose(args)
  else
    cnf = nil
	end
  LOGGING.info("check_cnf_config cnf: #{cnf}")
  cnf
end

def check_all_cnf_args(args)
  LOGGING.debug "args = #{args.inspect}" if check_verbose(args)
  cnf = check_cnf_config(args)
  deploy_with_chart = true
  if cnf 
    LOGGING.info "all cnf: #{cnf}" if check_verbose(args)
    if args.named["deploy_with_chart"]? && args.named["deploy_with_chart"] == "false"
      deploy_with_chart = false
    end
	end
  return cnf, deploy_with_chart
end

def check_cnf_config_then_deploy(args)
  config_file, deploy_with_chart = check_all_cnf_args(args)
  sample_setup_args(sample_dir: config_file, deploy_with_chart: deploy_with_chart, args: args, verbose: check_verbose(args) ) if config_file
end

def task_runner(args, &block : Sam::Args -> String | Colorize::Object(String) | Nil)
  # LOGGING.info("single_or_all_cnfs_task_runner: #{args.inspect}")
  if check_cnf_config(args)
    single_task_runner(args, &block)
  else
    all_cnfs_task_runner(args, &block)
  end
end

# TODO give example for calling
def all_cnfs_task_runner(args, &block : Sam::Args -> String | Colorize::Object(String) | Nil)
  # LOGGING.info("all_cnfs_task_runner cnf_config_list: #{cnf_config_list.inspect}")
  cnf_config_list.map do |x|
    # LOGGING.info("all_cnfs_task_runner config_list x: #{x}")
    new_args = Sam::Args.new(args.named, args.raw)
    new_args.named["cnf-config"] = x
    # LOGGING.info("all_cnfs_task_runner new_args: #{new_args.inspect}")
    single_task_runner(new_args, &block)
  end
end

# TODO give example for calling
def single_task_runner(args, &block)
  # LOGGING.info("task_runner args: #{args.inspect}")
  begin
  yield args
  rescue ex
    LOGGING.error ex.message
    ex.backtrace.each do |x|
      LOGGING.error x
    end
  end
end

def toggle(toggle_name)
  toggle_on = false
  if File.exists?(BASE_CONFIG)
    config = Totem.from_file BASE_CONFIG 
    if config["toggles"].as_a?
      feature_flag = config["toggles"].as_a.find do |x| 
        x["name"] == toggle_name
      end
      toggle_on = feature_flag["toggle_on"].as_bool if feature_flag
    end
  else
    toggle_on = false
  end
  toggle_on
end

## check feature level e.g. --beta
## if no feature level then feature level = ga
def check_feature_level(args)
  case args.raw
  when .includes? "alpha"
    "alpha"
  when .includes? "beta"
    "beta"
  when .includes? "wip"
    "wip"
  else
    "ga"
  end
end

# cncf/cnf-conformance/issues/106
# Requesting beta tests to run will both beta and ga flagged tests
# Requesting alpha tests will run alpha, beta, and ga flagged tests
# Requesting wip tests will run wip, poc, beta, and ga flagged tests

# if the beta flag is not true but the alpha is true, then beta tests should be run
def check_beta
  toggle("beta") || check_alpha
end

# if the beta flag is not true but the alpha is true, then beta tests should be run
def check_beta(args)
  toggle("beta") || check_feature_level(args) == "beta" || check_alpha(args)
end

# if the alpha flag is not true but the wip is true, then alpha tests should be run
def check_alpha
  toggle("alpha") || check_wip
end

# if the alpha flag is not true but the wip is true, then alpha tests should be run
def check_alpha(args)
  toggle("alpha") || check_feature_level(args) == "alpha" || check_wip(args)
end

def check_wip
  toggle("wip")
end

def check_wip(args)
  toggle("wip") || check_feature_level(args) == "wip"
end

def template_results_yml
  #TODO add tags for category summaries
  YAML.parse <<-END
name: cnf conformance 
status: 
points: 
items: []
END
end

def create_final_results_yml_name
  FileUtils.mkdir_p("results") unless Dir.exists?("results")
  "results/cnf-conformance-results-" + Time.local.to_s("%Y%m%d-%H%M%S-%L") + ".yml"
end

def create_points_yml
  unless File.exists?("#{POINTSFILE}")
    branch = ENV.has_key?("SCORING_ENV") ? ENV["SCORING_ENV"] : "master"
    default_scoring_yml = "https://raw.githubusercontent.com/cncf/cnf-conformance/#{branch}/scoring_config/#{DEFAULT_POINTSFILENAME}"
    `wget #{ENV.has_key?("SCORING_YML") ? ENV["SCORING_YML"] : default_scoring_yml}`
    `mv #{DEFAULT_POINTSFILENAME} #{POINTSFILE}`
  end
end

def delete_results_yml(verbose=false)
  if File.exists?("#{Results.file}")
    File.delete("#{Results.file}")
  end
end

def clean_results_yml(verbose=false)
  if File.exists?("#{Results.file}")
    results = File.open("#{Results.file}") do |f| 
      YAML.parse(f)
    end 
    File.open("#{Results.file}", "w") do |f| 
      YAML.dump({name: results["name"],
                 status: results["status"],
                 points: results["points"],
                 items: [] of YAML::Any}, f)
    end 
  end
end

def points_yml
  # TODO get points.yml from remote http
  points = File.open("points.yml") do |f| 
    YAML.parse(f)
  end 
  # LOGGING.debug "points: #{points.inspect}"
  points.as_a
end

def upsert_task(task, status, points)
  results = File.open("#{Results.file}") do |f| 
    YAML.parse(f)
  end 

  result_items = results["items"].as_a
  # remove the existing entry
  result_items = result_items.reject do |x| 
    x["name"] == task  
  end

  result_items << YAML.parse "{name: #{task}, status: #{status}, points: #{points}}"
  File.open("#{Results.file}", "w") do |f| 
    YAML.dump({name: results["name"],
               status: results["status"],
               points: results["points"],
               items: result_items}, f)
  end 
end

def failed_task(task, msg)
  upsert_task(task, FAILED, task_points(task, false))
  stdout_failure "#{msg}"
end

def passed_task(task, msg)
  upsert_task(task, PASSED, task_points(task))
  stdout_success "#{msg}"
end

def upsert_failed_task(task, message)
  upsert_task(task, FAILED, task_points(task, false))
  stdout_failure message
  message
end

def upsert_passed_task(task, message)
  upsert_task(task, PASSED, task_points(task))
  stdout_success message
  message
end

def task_points(task, passed=true)
  if passed
    field_name = "pass"
  else
    field_name = "fail"
  end
  points = points_yml.find {|x| x["name"] == task}
  LOGGING.warn "****Warning**** task #{task} not found in points.yml".colorize(:yellow) unless points
  if points && points[field_name]? 
    points[field_name].as_i if points
  else
    points = points_yml.find {|x| x["name"] == "default_scoring"}
    points[field_name].as_i if points
  end
end

def task_required(task)
  points = points_yml.find {|x| x["name"] == task}
  LOGGING.warn "task #{task} not found in points.yml".colorize(:yellow) unless points
  if points && points["required"]? && points["required"].as_bool == true
    true
  else
    false
  end
end

def failed_required_tasks
  yaml = File.open("#{Results.file}") do |file|
    YAML.parse(file)
  end
  yaml["items"].as_a.reduce([] of String) do |acc, i|
    if i["status"].as_s == "failed" && 
        i["name"].as_s? && 
        task_required(i["name"].as_s)
      (acc << i["name"].as_s)
    else
      acc
    end
  end
end

# def total_points
#   yaml = File.open("#{Results.file}") do |file|
#     YAML.parse(file)
#   end
#   yaml["items"].as_a.reduce(0) do |acc, i|
#     if i["points"].as_i?
#       (acc + i["points"].as_i)
#     else
#       acc
#     end
#   end
# end

def total_points(tag=nil)
  if tag
    tasks = tasks_by_tag(tag)
  else
    tasks = all_task_test_names
  end
  yaml = File.open("#{Results.file}") do |file|
    YAML.parse(file)
  end
  yaml["items"].as_a.reduce(0) do |acc, i|
    if i["points"].as_i? && i["name"].as_s? &&
        tasks.find{|x| x == i["name"]}
      (acc + i["points"].as_i)
    else
      acc
    end
  end
end

def total_max_points(tag=nil)
  if tag
    tasks = tasks_by_tag(tag)
  else
    tasks = all_task_test_names
  end
  tasks.reduce(0) do |acc, x|
    points = task_points(x)
    if points
      acc + points
    else
      acc
    end
  end
end

def all_task_test_names
  result_items = points_yml.reduce([] of String) do |acc, x|
    if x["name"].as_s == "default_scoring"
      acc
    else
      acc << x["name"].as_s
    end
  end
end

def tasks_by_tag(tag)
  #TODO cross reference points.yml tags with results
  found = false
  result_items = points_yml.reduce([] of String) do |acc, x|
    if x["tags"].as_s? && x["tags"].as_s.includes?(tag)
      acc << x["name"].as_s
    else
      acc
    end
  end
end

def all_result_test_names(results_file)
  results = File.open(results_file) do |f| 
    YAML.parse(f)
  end 
  result_items = results["items"].as_a.reduce([] of String) do |acc, x|
      acc << x["name"].as_s
  end
end

def results_by_tag(tag)
  task_list = tasks_by_tag(tag)

  results = File.open("#{Results.file}") do |f| 
    YAML.parse(f)
  end 

  found = false
  result_items = results["items"].as_a.reduce([] of YAML::Any) do |acc, x|
    if x["name"].as_s? && task_list.find{|tl| tl == x["name"].as_s}
      acc << x
    else
      acc
    end
  end
end

def stdout_info(msg) 
  puts msg
end

def stdout_success(msg)
  puts msg.colorize(:green)
end

def stdout_warning(msg)
  puts msg.colorize(:yellow)
end

def stdout_failure(msg)
  puts msg.colorize(:red)
end

def stdout_score(test_name)
  total = total_points(test_name)
  pretty_test_name = test_name.split("_").map(&.capitalize).join(" ")
  test_log_msg = "#{pretty_test_name} final score: #{total} of #{total_max_points(test_name)}"

  if total > 0
    stdout_success test_log_msg
  else
    stdout_failure test_log_msg
  end
end