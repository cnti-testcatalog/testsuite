require "totem"
require "colorize"
require "./cnf_manager.cr"
require "./embedded_file_manager.cr"
require "log"
require "file_utils"
require "option_parser"
require "../constants.cr"
require "semantic_version"
require "./dockerd.cr"
require "./kyverno.cr"
require "./http_helper.cr"
require "ecr"

module ShellCmd
  def self.run(cmd, log_prefix, force_output=false)
    Log.info { "#{log_prefix} command: #{cmd}" }
    status = Process.run(
      cmd,
      shell: true,
      output: output = IO::Memory.new,
      error: stderr = IO::Memory.new
    )
    if force_output == false
      Log.debug { "#{log_prefix} output: #{output.to_s}" }
    else
      Log.info { "#{log_prefix} output: #{output.to_s}" }
    end

    # Don't have to output log line if stderr is empty
    if stderr.to_s.size > 1
      Log.info { "#{log_prefix} stderr: #{stderr.to_s}" }
    end
    {status: status, output: output.to_s, error: stderr.to_s}
  end
end

def ensure_kubeconfig!

  kubeconfig_path = File.join(ENV["HOME"], ".kube", "config")
  
  if ENV.has_key?("KUBECONFIG") && File.exists?(ENV["KUBECONFIG"])
    puts "KUBECONFIG is already set.".colorize(:green)
  elsif File.exists?(kubeconfig_path)
    ENV["KUBECONFIG"] = kubeconfig_path
    puts "KUBECONFIG is set as #{ENV["KUBECONFIG"]}.".colorize(:green)
  else
    puts "KUBECONFIG is not set. Please set a KUBECONFIG, i.p 'export KUBECONFIG=path-to-your-kubeconfig'".colorize(:red)
    raise "KUBECONFIG is not set. Please set a KUBECONFIG, i.p 'export KUBECONFIG=path-to-your-kubeconfig'"
  end

end

def log_formatter
  Log::Formatter.new do |entry, io|
    progname = "cnf-testsuite"
    label = entry.severity.none? ? "ANY" : entry.severity.to_s.upcase
    msg = entry.source.empty? ? "#{progname}: #{entry.message}" : "#{progname}-#{entry.source}: #{entry.message}"
    io << label[0] << ", [" << entry.timestamp << " #" << Process.pid << "] "
    io << label.rjust(5) << " -- " << msg
  end
end

class LogLevel
  class_property command_line_loglevel : String = ""
end

begin
  OptionParser.parse do |parser|
    parser.banner = "Usage: cnf-testsuite [arguments]"
    parser.on("-l LEVEL", "--loglevel=LEVEL", "Specifies the logging level for cnf-testsuite suite") do |level|
      LogLevel.command_line_loglevel = level
    end
    parser.on("-h", "--help", "Show this help") { puts parser }
  end
rescue ex : OptionParser::InvalidOption
  puts ex
end

# this first line necessary to make sure our custom formatter
# is used in the default error log line also
Log.setup(Log::Severity::Error, Log::IOBackend.new(formatter: log_formatter))
Log.setup(loglevel, Log::IOBackend.new(formatter: log_formatter))


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

  if ENV.has_key?("LOG_LEVEL")
    levelstr = ENV["LOG_LEVEL"]
  end

  # highest priority is last
  if !LogLevel.command_line_loglevel.empty?
    levelstr = LogLevel.command_line_loglevel
  end

  if Log::Severity.parse?(levelstr)
    Log::Severity.parse(levelstr)
  else
    if !levelstr.empty?
      Log.error { "Invalid logging level set. defaulting to ERROR" }
    end
    # if nothing set but also nothing missplled then silently default to error
    Log::Severity::Error
  end
end

# TODO: get rid of LogginGenerator and VerboseLogginGenerator evil sourcery and refactor the rest of the code to use Log + procs directly
class LogginGenerator
  macro method_missing(call)
    if {{ call.name.stringify }} == "debug"
      Log.debug {{{call.args[0]}}}
    end
    if {{ call.name.stringify }} == "info"
      Log.info {{{call.args[0]}}}
    end
    if {{ call.name.stringify }} == "warn"
      Log.warn {{{call.args[0]}}}
    end
    if {{ call.name.stringify }} == "error"
      Log.error {{{call.args[0]}}}
    end
    if {{ call.name.stringify }} == "fatal"
      Log.fatal {{{call.args[0]}}}
    end
  end
end

class VerboseLogginGenerator
  macro method_missing(call)
    source = "verbose"
    if {{ call.name.stringify }} == "debug"
      Log.for(source).debug {{{call.args[0]}}}
    end
    if {{ call.name.stringify }} == "info"
      Log.for(source).info {{{call.args[0]}}}
    end
    if {{ call.name.stringify }} == "warn"
      Log.for(source).warn {{{call.args[0]}}}
    end
    if {{ call.name.stringify }} == "error"
      Log.for(source).error {{{call.args[0]}}}
    end
    if {{ call.name.stringify }} == "fatal"
      Log.for(source).fatal {{{call.args[0]}}}
    end
  end
end

LOGGING = LogginGenerator.new
VERBOSE_LOGGING = VerboseLogginGenerator.new


def check_verbose(args)
  ((args.raw.includes? "verbose") || (args.raw.includes? "v"))
end

def check_cnf_config(args)
  VERBOSE_LOGGING.debug "args = #{args.inspect}" if check_verbose(args)
  LOGGING.info("check_cnf_config args: #{args.inspect}")
  if args.named.keys.includes? "cnf-config"
    yml_file = args.named["cnf-config"].as(String)
    cnf = File.dirname(yml_file)
    VERBOSE_LOGGING.info "all cnf: #{cnf}" if check_verbose(args)
  else
    cnf = nil
	end
  LOGGING.info("check_cnf_config cnf: #{cnf}")
  cnf
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
  LOGGING.info "args.raw #{args.raw}"
  case args.raw
  when .includes? "poc"
    "poc"
  when .includes? "wip"
    "wip"
  when .includes? "alpha"
    "alpha"
  when .includes? "beta"
    "beta"
  else
    "ga"
  end
end

# cncf/cnf-testsuite/issues/106
# Requesting beta tests to run will both beta and ga flagged tests
# Requesting alpha tests will run alpha, beta, and ga flagged tests
# Requesting wip tests will run wip, poc, alpha, beta, and ga flagged tests

# if the beta flag or alpha flag is true, then beta tests should be run
def check_beta
  toggle("beta") || check_alpha
end

# if the beta flag or alpha flag is true, then beta tests should be run
def check_beta(args)
  toggle("beta") || check_feature_level(args) == "beta" || check_alpha(args)
end

# if the alpha flag or wip flag is true, then alpha tests should be run
def check_alpha
  toggle("alpha") || check_wip
end

# if the alpha flag or wip flag is true, then alpha tests should be run
def check_alpha(args)
  toggle("alpha") || check_feature_level(args) == "alpha" || check_wip(args)
end

def check_wip
  toggle("wip") || toggle("poc")
end

def check_wip(args)
  toggle("wip") || check_feature_level(args) == "wip" ||
  toggle("poc") || check_feature_level(args) == "poc"
end

def check_poc
  check_wip
end

def check_containerd
  resp = KubectlClient::Get.container_runtimes
  containerd = false
  resp.each do |x|
    if (x =~ /containerd/)
      containerd = true
    end
    Log.info { "Containerd?: #{containerd}" }
  end
  containerd
end

def check_poc(args)
  check_wip(args)
end

def check_destructive
  toggle("destructive")
end

def check_destructive(args)
  LOGGING.info "args.raw #{args.raw}"
  toggle("destructive") || args.raw.includes?("destructive")
end

def update_yml(yml_file, top_level_key, value)
  results = File.open("#{yml_file}") do |f|
    YAML.parse(f)
  end
  LOGGING.debug "update_yml results: #{results}"
  # The last key assigned wins
  new_yaml = YAML.dump(results) + "\n#{top_level_key}: #{value}"
  parsed_new_yml = YAML.parse(new_yaml)
  LOGGING.debug "update_yml parsed_new_yml: #{parsed_new_yml}"
  File.open("#{yml_file}", "w") do |f|
    YAML.dump(parsed_new_yml,f)
  end
end

def upsert_decorated_task(task, status : CNFManager::ResultStatus, message, start_time)
  tc_emoji = CNFManager::Points.emoji_by_task(task)
  cat_emoji = CNFManager::Points.task_emoji_by_task(task)
  case status.to_basic
  when CNFManager::ResultStatus::Passed
    upsert_passed_task(task, "✔️  #{cat_emoji}PASSED: #{message} #{tc_emoji}", start_time)
  when CNFManager::ResultStatus::Failed
    upsert_failed_task(task, "✖️  #{cat_emoji}FAILED: #{message} #{tc_emoji}", start_time)
  when CNFManager::ResultStatus::Skipped
    upsert_skipped_task(task, "⏭️  #{cat_emoji}SKIPPED: #{message} #{tc_emoji}", start_time)
  when CNFManager::ResultStatus::NA
    upsert_na_task(task, "⏭️  #{cat_emoji}N/A: #{message} #{tc_emoji}", start_time)
  end
end

def upsert_failed_task(task, message, start_time)
 CNFManager::Points.upsert_task(task, FAILED, CNFManager::Points.task_points(task, false), start_time)
  stdout_failure message
  message
end

def upsert_passed_task(task, message, start_time)
 CNFManager::Points.upsert_task(task, PASSED, CNFManager::Points.task_points(task), start_time)
  stdout_success message
  message
end

def upsert_skipped_task(task, message, start_time)
 CNFManager::Points.upsert_task(task, SKIPPED, CNFManager::Points.task_points(task, CNFManager::ResultStatus::Skipped), start_time)
  stdout_warning message
  message
end

def upsert_na_task(task, message, start_time)
 CNFManager::Points.upsert_task(task, NA, CNFManager::Points.task_points(task, CNFManager::ResultStatus::NA), start_time)
  stdout_warning message
  message
end

def upsert_dynamic_task(task, status : CNFManager::ResultStatus, message, start_time)
  CNFManager::Points.upsert_task(task, status.to_s.downcase, CNFManager::Points.task_points(task, status), start_time)
  case status.to_s.downcase 
  when /pass/
    stdout_success message
  when /fail/
  stdout_failure message
  message
  else
    stdout_warning message
  end
  message
end

def testsuite_resources_dir
  default_dir = "#{ENV["HOME"]}/.cnf-testsuite"
  testsuite_dir = ENV.fetch("CNF_TESTSUITE_DIR", default_dir)
  FileUtils.mkdir_p(testsuite_dir) if !Dir.exists?(testsuite_dir)
  return testsuite_dir
end

def tools_path
  value = "#{testsuite_resources_dir}/tools"
  FileUtils.mkdir_p(value) if !Dir.exists?(value)
  value
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
  stdout_score(test_name, test_name)
end

def stdout_score(test_name : String, full_name)
  stdout_score([test_name], full_name)
end

def stdout_score(test_names : Array(String), full_name)
  total = CNFManager::Points.total_points(test_names)
  max_points = CNFManager::Points.total_max_points(test_names)
  total_passed = CNFManager::Points.total_passed(test_names)
  max_passed = CNFManager::Points.total_max_passed(test_names)
  essential_total_passed = CNFManager::Points.total_passed("essential")
  essential_max_passed = CNFManager::Points.total_max_passed("essential")

  pretty_test_name = full_name.split(/:|_/).map(&.capitalize).join(" ")
  test_log_msg = 
<<-STRING
#{pretty_test_name} results: #{total_passed} of #{max_passed} tests passed

STRING

  update_yml("#{CNFManager::Points::Results.file}", "points", total)
  update_yml("#{CNFManager::Points::Results.file}", "maximum_points", max_points)

  if total > 0
    stdout_success test_log_msg
  else
    stdout_failure test_log_msg
  end
end
  

# this method extracts a string value from a config section if it exists
# if the value is an integer it will be converted to a string before extraction
def optional_key_as_string(totem_config, key_name)
  "#{totem_config[key_name]? && (totem_config[key_name].as_s? || totem_config[key_name].as_i?)}"
end

# compare 2 SemVer strings and return true if v1 is less than v2
def version_less_than(v1str, v2str)
  # k3s verisons look like this (valid semantic version): 1.23.6+k3s1
  #
  # microk8s verisons look like this (invalid semantic version): 1.20+.0
  #
  # microk8s version strings are bad input to the semantic version parser.
  # To allow microk8s, we strip the plus sign from the minor version.
  # The below code block performs that cleanup.

  v1str = v1str.split(".").map {|i| i.ends_with?("+") ? i.gsub("+", "") : i}
  v1str = v1str.join(".")
  v2str = v2str.split(".").map {|i| i.ends_with?("+") ? i.gsub("+", "") : i}
  v2str = v2str.join(".")

  v1 = SemanticVersion.parse(v1str)
  v2 = SemanticVersion.parse(v2str)
  less_than = (v1 <=> v2) == -1
  LOGGING.debug "version_less_than: #{v1} < #{v2}: #{less_than}"
  less_than
end

def generate_cm_name(prefix : String = "test-cm-") : String
  "#{prefix}-#{Random::Secure.rand(9999).to_s}"
 end
 
 def get_full_pod_name(part_of_pod_name : String, namespace : String = "default") : String?
  return nil if part_of_pod_name.empty?
  command_output = KubectlClient::ShellCmd.run("kubectl get po -A", "", false)
  return nil unless command_output[:status].success?
  output = command_output["output"]
  match = output.match(%r{(\S*#{part_of_pod_name}\S*)})
  match ? match[1].to_s : nil
 end
 
 def get_etcd_certs_path(etcd_pod_name : String, namespace : String) : String?
  command_output = KubectlClient.describe("po", etcd_pod_name, namespace)
  return nil unless command_output[:status].success?
  output = command_output["output"]
  match = output.match(%r{etcd-certs:\s+Type:.*\n\s+Path: (.*)(?:\n|$)})
  match ? match[1].to_s : nil
 end
 
 def etcd_cm_encrypted?(
  etcd_certs_path : String, 
  etcd_pod_name : String, 
  cm_name : String, 
  test_cm_value : String, 
  namespace : String,
  override_output : String? = nil
  ) : Bool
  etcd_output = override_output || execute_etcd_command(etcd_certs_path, etcd_pod_name, cm_name, namespace)
  puts "Etcd Output: #{etcd_output}"
  etcd_output.includes?("k8s:enc:") && !etcd_output.includes?(test_cm_value)
 end
 
 private def execute_etcd_command(etcd_certs_path : String, etcd_pod_name : String, cm_name : String, namespace : String) : String
  command = "ETCDCTL_API=3 etcdctl \
     --cacert #{etcd_certs_path}/ca.crt \
     --cert #{etcd_certs_path}/server.crt \
     --key #{etcd_certs_path}/server.key \
     get /registry/configmaps/default/#{cm_name}"
  io = IO::Memory.new
  Process.run("kubectl", ["exec", "-it", etcd_pod_name, "-n", namespace, "--", "sh", "-c", "#{command}"], output: io)
  io.to_s
 end
 