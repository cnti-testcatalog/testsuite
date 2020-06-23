# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "The CNF conformance suite checks if state is stored in a custom resource definition or a separate database (e.g. etcd) rather than requiring local storage.  It also checks to see if state is resilient to node failure"
task "statelessness", ["volume_hostpath_not_found"] do |_, args|
  total = total_points("statelessness")
  if total > 0
    puts "Statelessness final score: #{total} of #{total_max_points("statelessness")}".colorize(:green)
  else
    puts "Statelessness final score: #{total} of #{total_max_points("statelessness")}".colorize(:red)
  end
end

desc "Does the CNF use a non-cloud native data store: hostPath volume"
task "volume_hostpath_not_found", ["retrieve_manifest"] do |_, args|
  failed_emoji = "(ভ_ভ) ރ 💾"
  passed_emoji = "🖥️  💾"
  task_response = task_runner(args) do |args|
    puts "volume_hostpath_not_found" if check_verbose(args)
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = cnf_destination_dir(ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    deployment = Totem.from_file "#{destination_cnf_dir}/manifest.yml"
    puts deployment.inspect if check_verbose(args)

    hostPath_found = nil 
    begin
      volumes = deployment.get("spec").as_h["template"].as_h["spec"].as_h["volumes"].as_a
      hostPath_found = volumes.find do |volume| 
        if volume.as_h["hostPath"]?
             true
        end
      end
    rescue ex
      puts ex.message if check_args(args)
      upsert_failed_task("volume_hostpath_not_found","✖️  FAILURE: hostPath volumes found #{failed_emoji}")
    end

    if hostPath_found 
      upsert_failed_task("volume_hostpath_not_found","✖️  FAILURE: hostPath volumes found #{failed_emoji}")
    else
      upsert_passed_task("volume_hostpath_not_found","✔️  PASSED: hostPath volumes not found #{passed_emoji}")
    end
  end
end
