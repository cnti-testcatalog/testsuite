# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "The CNF conformance suite checks if state is stored in a custom resource definition or a separate database (e.g. etcd) rather than requiring local storage.  It also checks to see if state is resilient to node failure"
task "statelessness", ["volume_hostpath_not_found"] do |_, args|
  stdout_score("statelessness")
end

desc "Does the CNF use a non-cloud native data store: hostPath volume"
task "volume_hostpath_not_found", ["retrieve_manifest"] do |_, args|
  failed_emoji = "(ভ_ভ) ރ 💾"
  passed_emoji = "🖥️  💾"
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "volume_hostpath_not_found" if check_verbose(args)
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    deployment = Totem.from_file "#{destination_cnf_dir}/manifest.yml"
    VERBOSE_LOGGING.info deployment.inspect if check_verbose(args)

    hostPath_found = nil 
    begin
      # TODO check to see if this fails with container storage (and then erroneously fails the test as having hostpath volumes)
      volumes = deployment.get("spec").as_h["template"].as_h["spec"].as_h["volumes"].as_a
      hostPath_found = volumes.find do |volume| 
        if volume.as_h["hostPath"]?
             true
        end
      end
    rescue ex
      VERBOSE_LOGGING.error ex.message if check_verbose(args)
      upsert_failed_task("volume_hostpath_not_found","✖️  FAILURE: hostPath volumes found #{failed_emoji}")
    end

    if hostPath_found 
      upsert_failed_task("volume_hostpath_not_found","✖️  FAILURE: hostPath volumes found #{failed_emoji}")
    else
      upsert_passed_task("volume_hostpath_not_found","✔️  PASSED: hostPath volumes not found #{passed_emoji}")
    end
  end
end

desc "Does the CNF use a non-cloud native data store: local volumes on the node?"
task "no_local_volume_configuration", ["retrieve_manifest"] do |_, args|
  failed_emoji = "(ভ_ভ) ރ 💾"
  passed_emoji = "🖥️  💾"
  task_response = task_runner(args) do |args|
    VERBOSE_LOGGING.info "no_local_volume_configuration" if check_verbose(args)
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    # TODO get manifest from constant or args
    deployment = Totem.from_file "#{destination_cnf_dir}/manifest.yml"
    VERBOSE_LOGGING.info deployment.inspect if check_verbose(args)

    hostPath_found = nil 
    begin
      # TODO if any volume claim templates have a local-storage classname, fail the test
      storage_class_name = deployment.get("spec").as_h["storageClassName"].as_s
        
      # local_storage_found = volumeClaims.find do |volume_claim| 
      #   if volume_claim.as_h["spec"].as_h["storageClassName"].as_s? &&
      #       volume_claim.as_h["spec"].as_h["storageClassName"].as_s == "local-storage" 
      #        true
      #   end
        if storage_class_name == "local-storage"
         local_storage_found = true
        else
         local_storage_found = false
        end
      # end
    rescue ex
      VERBOSE_LOGGING.error ex.message if check_verbose(args)
      upsert_passed_task("no_local_volume_configuration","✔️  PASSED: local storage configuration volumes not found #{passed_emoji}")
    end

    if local_storage_found 
      upsert_failed_task("no_local_volume_configuration","✖️  FAILURE: local storage configuration volumes found #{failed_emoji}")
    else
      upsert_passed_task("no_local_volume_configuration","✔️  PASSED: local storage configuration volumes not found #{passed_emoji}")
    end
  end
end
