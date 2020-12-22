# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"
require "../utils/kubectl_client.cr"

desc "The CNF conformance suite checks if state is stored in a custom resource definition or a separate database (e.g. etcd) rather than requiring local storage.  It also checks to see if state is resilient to node failure"
task "statelessness", ["volume_hostpath_not_found"] do |_, args|
  stdout_score("statelessness")
end

desc "Does the CNF use a non-cloud native data store: hostPath volume"
task "volume_hostpath_not_found", ["retrieve_manifest"] do |_, args|
  task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "volume_hostpath_not_found" if check_verbose(args)
    failed_emoji = "(ভ_ভ) ރ 💾"
    passed_emoji = "🖥️  💾"
    LOGGING.debug "cnf_config: #{config}"
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    # config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    # destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    # TODO loop through all deployments
    deployment = Totem.from_file "#{destination_cnf_dir}/manifest.yml"
    # VERBOSE_LOGGING.info deployment.inspect if check_verbose(args)
    # TODO use new workload_yml function
    task_response = CNFManager.workload_resource_test(args, config, check_containers=false) do |resource|

      hostPath_found = nil 
      begin
        # TODO check to see if this fails with container storage (and then erroneously fails the test as having hostpath volumes)
        volumes = deployment.get("spec").as_h["template"].as_h["spec"].as_h["volumes"].as_a
        hostPath_not_found = volumes.none? do |volume| 
          if volume.as_h["hostPath"]?
              true
          end
        end
      rescue ex
        VERBOSE_LOGGING.error ex.message if check_verbose(args)
        puts "✖️  FAILURE: On resource #{deployment}, hostPath volumes found #{failed_emoji}".colorize(:red)
        hostPath_not_found = true
      end
      hostPath_not_found 
    end

    if task_response
      upsert_passed_task("volume_hostpath_not_found","✔️  PASSED: hostPath volumes not found #{passed_emoji}")
    else
      upsert_failed_task("volume_hostpath_not_found","✖️  FAILURE: hostPath volumes found #{failed_emoji}")
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
      # Note: A storageClassName value of "local-storage" is insufficient to determine if the
      # persistent volume is indeed local storage.  This is because the storageClass can be redefined
      # to be anything (e.g. the name local-storage can be redefined to be block storage behind the scenes) 

      volumes = [] of Totem::Any
      if deployment.get("spec").as_h["template"].as_h["spec"].as_h["volumes"]?
        volumes = deployment.get("spec").as_h["template"].as_h["spec"].as_h["volumes"].as_a 
      end
      LOGGING.debug "volumes: #{volumes}"
      persistent_volume_claim_names = volumes.map do |volume|
        # get persistent volume claim that matches persistent volume claim name
        if volume.as_h["persistentVolumeClaim"]? && volume.as_h["persistentVolumeClaim"].as_h["claimName"]?
            volume.as_h["persistentVolumeClaim"].as_h["claimName"]
          else
            nil 
          end
      end.compact
      LOGGING.debug "persistent volume claim names: #{persistent_volume_claim_names}"

      # TODO (optional) check storage class of persistent volume claim
      # loop through all pvc names
      # get persistent volume that matches pvc name
      # get all items, get spec, get claimRef, get pvc name that matches pvc name 
      local_storage_found = false
      persistent_volume_claim_names.map do | claim_name|
        items = KubectlClient::Get.pv_items_by_claim_name(claim_name)
        items.map do |item|
          begin
          if item["spec"]["local"]? && item["spec"]["local"]["path"]?
              local_storage_found = true
          end
          rescue ex
            LOGGING.info ex.message 
          end
        end
      end
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
