# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "The CNF test suite checks to see if RAN CNFs follow cloud native principles"
task "ran", ["oran_e2_connection"] do |_, args|
  stdout_score("ran")
  case "#{ARGV.join(" ")}" 
  when /ran/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end
desc "Test if RAN uses the ORAN e2 interface"
task "oran_e2_connection" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    task_start_time = Time.utc
    testsuite_task = "oran_e2_connection"
    Log.for(testsuite_task).info { "Starting test" }

    Log.debug { "cnf_config: #{config}" }
    release_name = config.cnf_config[:release_name]
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_testsuite_dir(args.named["cnf-config"].as(String)))
    if ORANMonitor.isCNFaRIC?(config.cnf_config) 
      configmap = KubectlClient::Get.configmap("cnf-testsuite-#{release_name}-startup-information")
      e2_found = configmap["data"].as_h["e2_found"].as_s


      if e2_found  == "true"
        resp = upsert_passed_task(testsuite_task,"✔️  PASSED: RAN connects to a RIC using the e2 standard interface", task_start_time)
      else
        resp = upsert_failed_task(testsuite_task, "✖️  FAILED: RAN does not connect to a RIC using the e2 standard interface", task_start_time)
      end
      resp
    else
      upsert_na_task(testsuite_task, "⏭️  N/A: [oran_e2_connection] No ric designated in cnf_testsuite.yml for #{destination_cnf_dir}", task_start_time)
      next
    end
  end

end
