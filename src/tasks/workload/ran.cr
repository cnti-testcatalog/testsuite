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
task "oran_e2_connection" do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    release_name = config.cnf_config[:release_name]
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_testsuite_dir(args.named["cnf-config"].as(String)))
    if ORANMonitor.isCNFaRIC?(config.cnf_config) 
      configmap = KubectlClient::Get.configmap("cnf-testsuite-#{release_name}-startup-information")
      e2_found = configmap["data"].as_h["e2_found"].as_s


      if e2_found  == "true"
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "RAN connects to a RIC using the e2 standard interface")
      else
        CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "RAN does not connect to a RIC using the e2 standard interface")
      end
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::NA, "[oran_e2_connection] No ric designated in cnf_testsuite.yml for #{destination_cnf_dir}")
    end
  end

end
