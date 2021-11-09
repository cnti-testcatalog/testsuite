require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "In order to maintain, debug, and have insight into a protected environment, its infrastructure elements must have the property of being observable. This means these elements must externalize their internal states in some way that lends itself to metrics, tracing, and logging."
task "observability", ["log_output"] do |_, args|
end

desc "Check if the CNF outputs logs to stdout or stderr"
task "log_output" do |_, args|
  CNFManager::Task.task_runner(args) do |args,config|
    Log.for("verbose").info { "log_output" } if check_verbose(args)

    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = false
      case resource["kind"].as_s.downcase
      when "replicaset", "deployment", "pod"
        result = KubectlClient.logs("#{resource["kind"]}/#{resource["name"]}", "--tail=5 --prefix=true")
        if result[:output].size > 0
          test_passed = true
        end
      end
      test_passed
    end

    emoji_observability="📶☠️"
    emoji_observability="📶☠️"

    if task_response
      upsert_passed_task("log_output", "✔️  PASSED: Resources output logs to stdout and stderr #{emoji_observability}")
    else
      upsert_failed_task("log_output", "✖️  FAILED: Resources do not output logs to stdout and stderr #{emoji_observability}")
    end
  end
end
