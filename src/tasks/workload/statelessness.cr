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

module Volume
  def self.elastic_by_volumes?(volumes, namespace : String? = nil)
    Log.info {"elastic_by_volumes"}
    storage_class_names = storage_class_by_volumes(volumes, namespace)
    elastic = StorageClass.elastic_by_storage_class?(storage_class_names)
    Log.info {"elastic_by_volumes elastic: #{elastic}"}
    elastic
  end
  # def self.elastic?(volumes, namespace : String? = nil)
  #   Log.info {"elastic? overload"}
  #   elastic?(volumes, namespace) {}
  # end
  # def self.elastic?(volumes, namespace : String? = nil, &block : -> JSON::Any | Nil)
  #   Log.info {"storge_class_by_volumes? "}
  #   Log.info {"storge_class_by_volumes? volumes: #{volumes}"}
  #   elastic = false
  #   #### default
  #   volume_claims = volumes.as_a.select{ |x| x.dig?("persistentVolumeClaim", "claimName") } 
  #   Log.info {"volume_claims #{volume_claims}"}
  #   dynamic_claims = volume_claims.reduce( [] of Hash(String, JSON::Any)) do |acc, claim| 
  #     resource = KubectlClient::Get.resource("pvc", claim.dig?("persistentVolumeClaim", "claimName"), namespace)
  #     Log.info {"pvc resource #{resource}"}
  #     # todo determine whether if resource uses a volume claim or a volume claim template
  #     # todo if no pvc
  #     # todo check for volumeClaimTemplate
  #     # todo  get metadata name field
  #     # todo  combine name <metatdataname>-<workloadresourcename>-0
  #     if block
  #       resource = yield unless resource
  #       Log.info {"block resource #{resource}"}
  #     else
  #       Log.info {"block is nil"}
  #     end
  #
  #     if resource && resource.dig?("spec", "storageClassName")
  #       Log.info {"StorageClass: #{resource.dig?("spec", "storageClassName")}"}
  #       acc << { "claim_name" =>  claim.dig("persistentVolumeClaim", "claimName"), "class_name" => resource.dig("spec", "storageClassName") }
  #     else
  #       acc
  #     end
  #   end
  #   Log.info {"Dynamic Claims: #{dynamic_claims}"}
  #   #todo elastic_by_storage_class?
  #   provisoners = dynamic_claims.reduce( [] of String) do |acc, claim| 
  #     resource = KubectlClient::Get.resource("storageclasses", claim.dig?("class_name"), namespace)
  #     if resource.dig?("provisioner")
  #       acc << resource.dig("provisioner").as_s 
  #     else
  #       acc
  #     end
  #   end
  #   Log.info {"Provisoners: #{provisoners}"}
  #   provisoners.each do |provisoner|
  #     if ENV["CRYSTAL_ENV"]? == "TEST"
  #       if (provisoner =~ ELASTIC_PROVISIONING_DRIVERS_REGEX_SPEC) 
  #         Log.info {"provisioner test mode"}
  #         Log.info {"Provisoners: #{provisoners}"}
  #         elastic = true
  #       end
  #     else
  #       if (provisoner =~ ELASTIC_PROVISIONING_DRIVERS_REGEX) 
  #         Log.info {"provisioner production mode"}
  #         Log.info {"Provisoners: #{provisoners}"}
  #         elastic = true
  #       end
  #     end
  #   end
  #   Log.info {"elastic? #{elastic}"}
  #   elastic
  # end

  def self.storage_class_by_volumes(volumes, namespace : String? = nil)
    Log.info {"storage_class_by_volumes? "}
    Log.info {"storage_class_by_volumes? volumes: #{volumes}"}
    volume_claims = volumes.as_a.select{ |x| x.dig?("persistentVolumeClaim", "claimName") } 
    Log.info {"volume_claims #{volume_claims}"}
    storage_class_names = volume_claims.reduce( [] of Hash(String, JSON::Any)) do |acc, claim| 
      resource = KubectlClient::Get.resource("pvc", claim.dig?("persistentVolumeClaim", "claimName"), namespace)
      Log.info {"pvc resource #{resource}"}

      if resource && resource.dig?("spec", "storageClassName")
        Log.info {"StorageClass: #{resource.dig?("spec", "storageClassName")}"}
        acc << { "claim_name" =>  claim.dig("persistentVolumeClaim", "claimName"), "class_name" => resource.dig("spec", "storageClassName") }
      else
        acc
      end
    end
    Log.info {"storage_class_names: #{storage_class_names}"}
    storage_class_names
  end
end
module StorageClass
  def self.elastic_by_storage_class?(storage_class_names : Array(Hash(String, JSON::Any)), 
                                     namespace : String? = nil)
    Log.info {"elastic_by_storage_class"}
    #todo elastic_by_storage_class?
    elastic = false
    provisoners = storage_class_names.reduce( [] of String) do |acc, storage_class| 
      resource = KubectlClient::Get.resource("storageclasses", storage_class.dig?("class_name"), namespace)
      if resource.dig?("provisioner")
        acc << resource.dig("provisioner").as_s 
      else
        acc
      end
    end
    Log.info {"Provisoners: #{provisoners}"}
    provisoners.each do |provisoner|
      if ENV["CRYSTAL_ENV"]? == "TEST"
        if (provisoner =~ ELASTIC_PROVISIONING_DRIVERS_REGEX_SPEC) 
          Log.info {"provisioner test mode"}
          Log.info {"Provisoners: #{provisoners}"}
          elastic = true
        end
      else
        if (provisoner =~ ELASTIC_PROVISIONING_DRIVERS_REGEX) 
          Log.info {"provisioner production mode"}
          Log.info {"Provisoners: #{provisoners}"}
          elastic = true
        end
      end
    end
    Log.info {"elastic? #{elastic}"}
    elastic
  end
end

module VolumeClaimTemplate
  def self.pvc_name_by_vct_resource(resource)
    Log.info {"vct_pvc_name"}
    resource_name = resource.dig?("metadata", "name")
    vct = resource.dig?("spec", "volumeClaimTemplates")
    if vct && vct.size > 0
      #K8s only supports one volume claim template per resource
      vct_name = vct[0].dig?("metadata", "name")
      name = "#{vct_name}-#{resource_name}-0"
    end
    Log.info {"name: #{name}"}
    name
  end

  def self.vct_resource?(resource)
    Log.info {" vct_resource??"}
    Log.info {" vct_resource? resource: #{resource}"}
    vct = resource.dig?("spec", "volumeClaimTemplates")
    Log.info {" vct_resource? vct: #{vct}"}
    if vct && vct.size > 0
      true
    else
      false
    end
  end

  def self.storage_class_by_vct_resource(resource, namespace)
    Log.info {"storage_class_by_vct_resource"}
    resource = KubectlClient::Get.resource("pvc", VolumeClaimTemplate.pvc_name_by_vct_resource(resource))

    Log.info {"pvc resource #{resource}"}
    storage_class = nil

    if resource && resource.dig?("spec", "storageClassName")
      Log.info {"StorageClass: #{resource.dig?("spec", "storageClassName")}"}
      # { "claim_name" =>  claim.dig("persistentVolumeClaim", "claimName"), "class_name" => resource.dig("spec", "storageClassName") }
      storage_class = { "class_name" => resource.dig("spec", "storageClassName") }
    end
    Log.info {"storage_class: #{storage_class}"}
    storage_class
  end 
end

module WorkloadResource 
  include Volume
  include VolumeClaimTemplate

  def self.elastic?(resource, volumes, namespace : String? = nil)
    Log.info {"workloadresource elastic?"}
    elastic = false
    if VolumeClaimTemplate.vct_resource?(resource)
      storage_class = VolumeClaimTemplate.storage_class_by_vct_resource(resource, namespace)
      if storage_class
        elastic = StorageClass.elastic_by_storage_class?([storage_class])
      end
    else
      elastic = Volume.elastic_by_volumes?(volumes)
    end
    Log.info {"workloadresource elastic?: #{elastic}"}
    elastic
  end
end


desc "Does the CNF use an elastic persistent volume"
task "elastic_volumes" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.info {"cnf_config: #{config}"}
    VERBOSE_LOGGING.info "elastic_volumes" if check_verbose(args)
    emoji_probe="🧫"
    elastic = false
    task_response = CNFManager.workload_resource_test(args, config, check_containers=false) do |resource, containers, volumes, initialized|
      Log.info {"resource: #{resource}"}
      Log.info {"volumes: #{volumes}"}
      # todo use workload resource
      # elastic = WorkloadResource.elastic?(volumes)
      namespace = CNFManager.namespace_from_parameters(CNFManager.install_parameters(config))

      full_resource = KubectlClient::Get.resource(resource["kind"], resource["name"], namespace)
      if WorkloadResource.elastic?(full_resource, volumes, namespace)  
        elastic = true
      end
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

desc "Does the CNF use a database which uses perisistence in a cloud native way"
task "database_persistence", ["install_cluster_tools"]  do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.info {"cnf_config: #{config}"}
    Log.info {"database_persistence"}
    # VERBOSE_LOGGING.info "database_persistence" if check_verbose(args)
    # todo K8s Database persistence test: if a mysql (or any popular database) image is installed:
    emoji_probe="🧫"
    elastic_statefulset = false
    elastic_volume_used = false
    statefulset_exists = false
    match = Mysql.match
    # VERBOSE_LOGGING.info "hithere" if check_verbose(args)
    Log.info {"hithere info"}
    Log.info {"database_persistence mysql: #{match}"}
    if match
      statefulset_exists = Helm.kind_exists?(args, config, "statefulset")
      task_response = CNFManager.workload_resource_test(args, config, check_containers=false) do |resource, containers, volumes, initialized|
        namespace = CNFManager.namespace_from_parameters(CNFManager.install_parameters(config))
        Log.info {"database_persistence namespace: #{namespace}"}
        Log.info {"database_persistence resource: #{resource}"}
        Log.info {"database_persistence volumes: #{volumes}"}
        # elastic_volume = Volume.elastic_by_volumes?(volumes)
        full_resource = KubectlClient::Get.resource(resource["kind"], resource["name"], namespace)
        elastic_volume = WorkloadResource.elastic?(full_resource, volumes, namespace)  
        Log.info {"database_persistence elastic_volume: #{elastic_volume}"}
        if elastic_volume
          elastic_volume_used = true
        end

        if resource["kind"].as_s.downcase == "statefulset" && elastic_volume
          elastic_statefulset = true
        end

      end
      failed_emoji = "(ভ_ভ) ރ 💾"
      if elastic_statefulset
        resp = upsert_dynamic_task("database_persistence",CNFManager::Points::Results::ResultStatus::Pass5, "✔️  PASSED: Elastic Volumes and Statefulsets Used #{emoji_probe}")
      elsif elastic_volume_used 
        resp = upsert_dynamic_task("database_persistence",CNFManager::Points::Results::ResultStatus::Pass3,"✔️  PASSED: Elastic Volumes Used #{emoji_probe}")
      elsif statefulset_exists
        resp = upsert_dynamic_task("database_persistence",CNFManager::Points::Results::ResultStatus::Neutral, "✖️  FAILED: Statefulset used without an elastic volume #{failed_emoji}")
      else
        resp = upsert_failed_task("database_persistence","✖️  FAILED: Elastic Volumes Not Used #{failed_emoji}")
      end

    else
      resp = upsert_skipped_task("database_persistence", "⏭️  SKIPPED: Mysql not installed #{emoji_probe}")
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
