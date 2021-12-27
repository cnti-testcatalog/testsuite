# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"
require "kubectl_client"

desc "The CNF test suite checks if state is stored in a custom resource definition or a separate database (e.g. etcd) rather than requiring local storage.  It also checks to see if state is resilient to node failure"
task "state", ["volume_hostpath_not_found", "no_local_volume_configuration", "elastic_volumes"] do |_, args|
  stdout_score("state")
end

ELASTIC_PROVISIONING_DRIVERS_REGEX = /kubernetes.io\/aws-ebs|kubernetes.io\/azure-file|kubernetes.io\/azure-disk|kubernetes.io\/cinder|kubernetes.io\/gce-pd|kubernetes.io\/glusterfs|kubernetes.io\/quobyte|kubernetes.io\/rbd|kubernetes.io\/vsphere-volume|kubernetes.io\/portworx-volume|kubernetes.io\/scaleio|kubernetes.io\/storageos|rook-ceph.rbd.csi.ceph.com/


ELASTIC_PROVISIONING_DRIVERS_REGEX_SPEC = /kubernetes.io\/aws-ebs|kubernetes.io\/azure-file|kubernetes.io\/azure-disk|kubernetes.io\/cinder|kubernetes.io\/gce-pd|kubernetes.io\/glusterfs|kubernetes.io\/quobyte|kubernetes.io\/rbd|kubernetes.io\/vsphere-volume|kubernetes.io\/portworx-volume|kubernetes.io\/scaleio|kubernetes.io\/storageos|rook-ceph.rbd.csi.ceph.com|rancher.io\/local-path/

desc "Does the CNF use an elastic persistent volume"
task "elastic_volumes" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    LOGGING.debug "cnf_config: #{config}"
    VERBOSE_LOGGING.info "elastic_volumes" if check_verbose(args)
    emoji_probe="🧫"
    elastic = false
    task_response = CNFManager.workload_resource_test(args, config, check_containers=false) do |resource, containers, volumes, initialized|
      LOGGING.info "resource: #{resource}"
      LOGGING.info "volumes: #{volumes}"
      volume_claims = volumes.as_a.select{ |x| x.dig?("persistentVolumeClaim", "claimName") } 
      dynamic_claims = volume_claims.reduce( [] of Hash(String, JSON::Any)) do |acc, claim| 
        resource = KubectlClient::Get.resource("pvc", claim.dig?("persistentVolumeClaim", "claimName"))
        LOGGING.info "StorageClass: #{resource.dig?("spec", "storageClassName")}"
        if resource.dig?("spec", "storageClassName")
          acc << { "claim_name" =>  claim.dig("persistentVolumeClaim", "claimName"), "class_name" => resource.dig("spec", "storageClassName") }
        else
          acc
        end
      end
      LOGGING.info "Dynamic Claims: #{dynamic_claims}"
      provisoners = dynamic_claims.reduce( [] of String) do |acc, claim| 
        resource = KubectlClient::Get.resource("storageclasses", claim.dig?("class_name"))
        if resource.dig?("provisioner")
             acc << resource.dig("provisioner").as_s 
           else
             acc
        end
      end
      LOGGING.info "Provisoners: #{provisoners}"
      provisoners.each do |provisoner|
         if ENV["CRYSTAL_ENV"]? == "TEST"
           if (provisoner =~ ELASTIC_PROVISIONING_DRIVERS_REGEX_SPEC) 
             LOGGING.info "provisioner test mode"
             LOGGING.info "Provisoners: #{provisoners}"
             elastic = true
           end
         else
           if (provisoner =~ ELASTIC_PROVISIONING_DRIVERS_REGEX) 
             LOGGING.info "provisioner production mode"
             LOGGING.info "Provisoners: #{provisoners}"
             elastic = true
           end
         end
      end
      elastic
    end
    if elastic
      resp = upsert_passed_task("elastic_volumes","✔️  PASSED: Elastic Volumes Used #{emoji_probe}")
    else
      resp = upsert_failed_task("elastic_volumes","✔️  FAILED: Elastic Volumes Not Used #{emoji_probe}")
    end
    resp
  end

  # TODO When using a default StorageClass, the storageclass name will be populated in the persistent volumes claim post-creation.
  # TODO Inspect the workload resource and search for any "Persistent Volume Claims" --> https://loft.sh/blog/kubernetes-persistent-volumes-examples-and-best-practices/#what-are-persistent-volume-claims-pvcs 
  # TODO Inspect the Persistent Volumes Claim and determine if a Storage Class is use. If a Storage Class is defined, dynamic provisioning is in use. If no storge class is defined, static provisioningis in use -> https://v1-20.docs.kubernetes.io/docs/concepts/storage/persistent-volumes/#lifecycle-of-a-volume-and-claim

  # TODO If using dynamic provisioning, find the and inspect the associated storageClass and find the provisioning driver being used -> https://kubernetes.io/docs/concepts/storage/storage-classes/#the-storageclass-resource
  # TODO Match and check if the provisioning driver used is of an elastic volume type.
  # TODO If using static provisioning, find the and inspect the associated Persistent Volume and determine the provisioning driver being used -> 
  # TODO Match and check if the provisioning driver used is of an elastic volume type.
end

desc "Does the CNF use a non-cloud native data store: hostPath volume"
task "volume_hostpath_not_found" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "volume_hostpath_not_found" if check_verbose(args)
    failed_emoji = "(ভ_ভ) ރ 💾"
    passed_emoji = "🖥️  💾"
    LOGGING.debug "cnf_config: #{config}"
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.cnf_workload_resources(args, config) do | resource|
      hostPath_found = nil 
      begin
        # TODO check to see if volume is actually mounted.  Check to see if mount (without volume) has host path as well
        volumes = resource.dig?("spec", "template", "spec", "volumes")
        if volumes
          hostPath_not_found = volumes.as_a.none? do |volume| 
            if volume.as_h["hostPath"]?
                true
            end
          end
        else
          hostPath_not_found = true
        end
      rescue ex
        VERBOSE_LOGGING.error ex.message if check_verbose(args)
        puts "Rescued: On resource #{resource["metadata"]["name"]?} of kind #{resource["kind"]}, volumes not found. #{passed_emoji}".colorize(:yellow)
        hostPath_not_found = true
      end
      hostPath_not_found 
    end

    if task_response.any?(false)
      upsert_failed_task("volume_hostpath_not_found","✖️  FAILED: hostPath volumes found #{failed_emoji}")
    else
      upsert_passed_task("volume_hostpath_not_found","✔️  PASSED: hostPath volumes not found #{passed_emoji}")
    end
  end
end

desc "Does the CNF use a non-cloud native data store: local volumes on the node?"
task "no_local_volume_configuration" do |_, args|
  failed_emoji = "(ভ_ভ) ރ 💾"
  passed_emoji = "🖥️  💾"
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "no_local_volume_configuration" if check_verbose(args)

    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    task_response = CNFManager.cnf_workload_resources(args, config) do | resource|
      hostPath_found = nil 
      begin
        # Note: A storageClassName value of "local-storage" is insufficient to determine if the
        # persistent volume is indeed local storage.  This is because the storageClass can be redefined
        # to be anything (e.g. the name local-storage can be redefined to be block storage behind the scenes) 

        volumes = [] of YAML::Any
        if resource["spec"].as_h["template"].as_h["spec"].as_h["volumes"]?
            volumes = resource["spec"].as_h["template"].as_h["spec"].as_h["volumes"].as_a 
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
        local_storage_not_found = true 
        persistent_volume_claim_names.map do | claim_name|
          items = KubectlClient::Get.pv_items_by_claim_name(claim_name)
          items.map do |item|
            begin
              if item["spec"]["local"]? && item["spec"]["local"]["path"]?
                  local_storage_not_found = false 
              end
            rescue ex
              LOGGING.info ex.message 
              local_storage_not_found = true 
            end
          end
        end
      rescue ex
        VERBOSE_LOGGING.error ex.message if check_verbose(args)
        puts "Rescued: On resource #{resource["metadata"]["name"]?} of kind #{resource["kind"]}, local storage configuration volumes not found #{passed_emoji}".colorize(:yellow)
        local_storage_not_found = true
      end
      local_storage_not_found
    end

    if task_response.any?(false) 
      upsert_failed_task("no_local_volume_configuration","✖️  FAILED: local storage configuration volumes found #{failed_emoji}")
    else
      upsert_passed_task("no_local_volume_configuration","✔️  PASSED: local storage configuration volumes not found #{passed_emoji}")
    end
  end
end
