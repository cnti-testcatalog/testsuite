require "totem"
require "colorize"
require "./sample_utils.cr"
# TODO make constants local or always retrieve from environment variables
# TODO Move constants out
# TODO put these functions into a module

CNF_DIR = "cnfs"
TOOLS_DIR = "tools"
# LOGFILE = "cnf-conformance-results-#{Time.utc.to_s("%Y%m%d")}.log"
LOGFILE = "results.yml"
POINTSFILE = "points.yml"
PASSED = "passed"
FAILED = "failed"
DEFAULT_POINTSFILENAME = "points_v1.yml"

def check_args(args)
  check_verbose(args)
end

def check_verbose(args)
  if ((args.raw.includes? "verbose") || (args.raw.includes? "v"))
    true
  else 
    false
  end
end

def toggle(toggle_name)
  toggle_on = false
  if File.exists?("./config.yml")
    config = Totem.from_file "./config.yml"
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
  "cnf-conformance-results-" + Time.local.to_s("%Y%m%d-%H%M%S-%L") + ".yml"
end

def create_points_yml
  unless File.exists?("#{POINTSFILE}")
    branch = ENV.has_key?("SCORING_ENV") ? ENV["SCORING_ENV"] : "master"
    default_scoring_yml = "https://raw.githubusercontent.com/cncf/cnf-conformance/#{branch}/scoring_config/#{DEFAULT_POINTSFILENAME}"
    `wget #{ENV.has_key?("SCORING_YML") ? ENV["SCORING_YML"] : default_scoring_yml}`
    `mv #{DEFAULT_POINTSFILENAME} #{POINTSFILE}`
  end
end

def create_results_yml(verbose=false)
  puts "create_results_yml"
  continue = false
  puts "file exists?:#{File.exists?(LOGFILE)}"
  if File.exists?("#{LOGFILE}")
    puts "Do you wish to overwrite the #{LOGFILE} file? If so, your previous results.yml will be lost."
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
    File.open("#{LOGFILE}", "w") do |f| 
      YAML.dump(template_results_yml, f)
    end 
  end
end

def points_yml
  # TODO get points.yml from remote http
  points = File.open("points.yml") do |f| 
    YAML.parse(f)
  end 
  # puts "points: #{points.inspect}"
  points.as_a
end

def upsert_task(task, status, points)
  results = File.open("#{LOGFILE}") do |f| 
    YAML.parse(f)
  end 
  found = false
  result_items = results["items"].as_a

  result_items << YAML.parse "{name: #{task}, status: #{status}, points: #{points}}"
  File.open("#{LOGFILE}", "w") do |f| 
    YAML.dump({name: results["name"],
               status: results["status"],
               points: results["points"],
               items: result_items}, f)
  end 
end

def failed_task(task, msg)
  upsert_task(task, FAILED, task_points(task, false))
  puts "#{msg}".colorize(:red)
end

def passed_task(task, msg)
  upsert_task(task, PASSED, task_points(task))
  puts "#{msg}".colorize(:green)
end

def upsert_failed_task(task)
  upsert_task(task, FAILED, task_points(task, false))
end

def upsert_passed_task(task)
  upsert_task(task, PASSED, task_points(task))
end

def task_points(task, passed=true)
  if passed
    field_name = "pass"
  else
    field_name = "fail"
  end
  points = points_yml.find {|x| x["name"] == task}
  puts "****Warning**** task #{task} not found in points.yml".colorize(:red) unless points
  if points && points[field_name]? 
    points[field_name].as_i if points
  else
    points = points_yml.find {|x| x["name"] == "default_scoring"}
    points[field_name].as_i if points
  end
end

def task_required(task)
  points = points_yml.find {|x| x["name"] == task}
  puts "task #{task} not found in points.yml" unless points
  if points && points["required"]? && points["required"].as_bool == true
    true
  else
    false
  end
end

def failed_required_tasks
  yaml = File.open("#{LOGFILE}") do |file|
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

def total_points
  yaml = File.open("#{LOGFILE}") do |file|
    YAML.parse(file)
  end
  yaml["items"].as_a.reduce(0) do |acc, i|
    if i["points"].as_i?
      (acc + i["points"].as_i)
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

  results = File.open("#{LOGFILE}") do |f| 
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


