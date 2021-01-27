# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "json"
require "../utils/utils.cr"

rolling_version_change_test_names = ["rolling_update", "rolling_downgrade", "rolling_version_change"]

desc "Configuration and lifecycle should be managed in a declarative manner, using ConfigMaps, Operators, or other declarative interfaces."
task "configuration_lifecycle", ["ip_addresses", "liveness", "readiness", "nodeport_not_used", "hardcoded_ip_addresses_in_k8s_runtime_configuration", "rollback"].concat(rolling_version_change_test_names) do |_, args|
  stdout_score("configuration_lifecycle")
end

desc "Does a search for IP addresses or subnets come back as negative?"
task "ip_addresses" do |_, args|
  task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "ip_addresses" if check_verbose(args)
    LOGGING.info("ip_addresses args #{args.inspect}")
    cdir = FileUtils.pwd()
    response = String::Builder.new
    helm_directory = config.cnf_config[:helm_directory]
    helm_chart_path = config.cnf_config[:helm_chart_path]
    if File.directory?(helm_chart_path)
      # Switch to the helm chart directory
      Dir.cd(helm_chart_path)
      # Look for all ip addresses that are not comments
      LOGGING.info "current directory: #{ FileUtils.pwd()}"
      # should catch comments (# // or /*) and ignore 0.0.0.0
      # note: grep wants * escaped twice
      Process.run("grep -r -P '^(?!.+0\.0\.0\.0)(?![[:space:]]*0\.0\.0\.0)(?!#)(?![[:space:]]*#)(?!\/\/)(?![[:space:]]*\/\/)(?!\/\\*)(?![[:space:]]*\/\\*)(.+([0-9]{1,3}[\.]){3}[0-9]{1,3})'", shell: true) do |proc|
        while line = proc.output.gets
          response << line
          VERBOSE_LOGGING.info "#{line}" if check_verbose(args)
        end
      end
      Dir.cd(cdir)
      if response.to_s.size > 0
        resp = upsert_failed_task("ip_addresses","✖️  FAILURE: IP addresses found")
      else
        resp = upsert_passed_task("ip_addresses", "✔️  PASSED: No IP addresses found")
      end
      resp
    else
      # TODO If no helm chart directory, exit with 0 points
      Dir.cd(cdir)
      resp = upsert_passed_task("ip_addresses", "✔️  PASSED: No IP addresses found")
    end
  end
end

desc "Is there a liveness entry in the helm chart?"
task "liveness" do |_, args|
  task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "liveness" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"
    resp = ""
    emoji_probe="🧫"
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
      begin
        VERBOSE_LOGGING.debug container.as_h["name"].as_s if check_verbose(args)
        container.as_h["livenessProbe"].as_h 
      rescue ex
        VERBOSE_LOGGING.error ex.message if check_verbose(args)
        test_passed = false 
        puts "No livenessProbe found for resource: #{resource} and container: #{container.as_h["name"].as_s}".colorize(:red)
      end
      LOGGING.debug "liveness test_passed: #{test_passed}"
      test_passed 
    end
    LOGGING.debug "liveness task response: #{task_response}"
    if task_response 
      resp = upsert_passed_task("liveness","✔️  PASSED: Helm liveness probe found #{emoji_probe}")
		else
			resp = upsert_failed_task("liveness","✖️  FAILURE: No livenessProbe found #{emoji_probe}")
    end
    resp
  end
end

desc "Is there a readiness entry in the helm chart?"
task "readiness" do |_, args|
  task_runner(args) do |args, config|
    LOGGING.debug "cnf_config: #{config}"
    VERBOSE_LOGGING.info "readiness" if check_verbose(args)
    # Parse the cnf-conformance.yml
    resp = ""
    emoji_probe="🧫"
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
      begin
        VERBOSE_LOGGING.debug container.as_h["name"].as_s if check_verbose(args)
        container.as_h["readinessProbe"].as_h 
      rescue ex
        VERBOSE_LOGGING.error ex.message if check_verbose(args)
        test_passed = false 
        puts "No readinessProbe found for resource: #{resource} and container: #{container.as_h["name"].as_s}".colorize(:red)
      end
      test_passed 
    end
    if task_response 
      resp = upsert_passed_task("readiness","✔️  PASSED: Helm readiness probe found #{emoji_probe}")
		else
      resp = upsert_failed_task("readiness","✖️  FAILURE: No readinessProbe found #{emoji_probe}")
    end
    resp
  end
end


desc "Retrieve the manifest for the CNF's helm chart"
task "retrieve_manifest" do |_, args| 
  # TODO put this in a function 
  task_runner(args) do |args|
    VERBOSE_LOGGING.info "retrieve_manifest" if check_verbose(args)
    # config = cnf_conformance_yml
    config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    # deployment_name = config.get("deployment_name").as_s
    #TODO loop through all services
    service_name = "#{config.get("service_name").as_s?}"
    # VERBOSE_LOGGING.debug "Deployment_name: #{deployment_name}" if check_verbose(args)
    VERBOSE_LOGGING.debug service_name if check_verbose(args)
    destination_cnf_dir = CNFManager.cnf_destination_dir(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    # TODO move to kubectl client
    # deployment = `kubectl get deployment #{deployment_name} -o yaml  > #{destination_cnf_dir}/manifest.yml`
    # KubectlClient::Get.save_manifest(deployment_name, "#{destination_cnf_dir}/manifest.yml")
    # VERBOSE_LOGGING.debug deployment if check_verbose(args)
    unless service_name.empty?
      # TODO move to kubectl client
      service = `kubectl get service #{service_name} -o yaml  > #{destination_cnf_dir}/service.yml`
    end
    VERBOSE_LOGGING.debug service if check_verbose(args)
    service
  end
end

rolling_version_change_test_names.each do |tn|
  pretty_test_name = tn.split(/:|_/).join(" ")
  pretty_test_name_capitalized = tn.split(/:|_/).map(&.capitalize).join(" ")

  desc "Test if the CNF containers are loosely coupled by performing a #{pretty_test_name}"
  task "#{tn}" do |_, args|
    task_runner(args) do |args, config|
      LOGGING.debug "cnf_config: #{config}"
      VERBOSE_LOGGING.info "#{tn}" if check_verbose(args)
      container_names = config.cnf_config[:container_names]
      LOGGING.debug "container_names: #{container_names}"
      update_applied = true
      unless container_names
        puts "Please add a container names set of entries into your cnf-conformance.yml".colorize(:red) 
        update_applied = false
      end

      # TODO use tag associated with image name string (e.g. busybox:v1.7.9) as the version tag
      # TODO optional get a valid version from the remote repo and roll to that, if no tag
      #  e.g. wget -q https://registry.hub.docker.com/v1/repositories/debian/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}'
      # note: all images are not on docker hub nor are they always on a docker hub compatible api

      task_response = update_applied && CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
        test_passed = true
        LOGGING.debug "#{tn} container: #{container}"
        LOGGING.debug "container_names: #{container_names}"
        config_container = container_names.find{|x| x["name"]==container.as_h["name"]} if container_names
        LOGGING.debug "config_container: #{config_container}"
        unless config_container && config_container["#{tn}_test_tag"]? && !config_container["#{tn}_test_tag"].empty?
          puts "Please add the container name #{container.as_h["name"]} and a corresponding #{tn}_test_tag into your cnf-conformance.yml under container names".colorize(:red)
          # valid_cnf_conformance_yml = false
        end

        if config_container
          resp = KubectlClient::Set.image(resource["name"], 
                                          container.as_h["name"], 
                                          # split out image name from version tag
                                          container.as_h["image"].as_s.split(":")[0], 
                                          config_container["rolling_update_test_tag"]) 
        else 
          resp = false
        end
        # If any containers dont have an update applied, fail
        test_passed = false if resp == false

        rollout_status = KubectlClient::Rollout.resource_status(resource["kind"], resource["name"])
        unless rollout_status 
          test_passed = false
        end
      end
      if task_response 
        resp = upsert_passed_task("#{tn}","✔️  PASSED: CNF for #{pretty_test_name_capitalized} Passed" )
      else
        resp = upsert_failed_task("#{tn}", "✖️  FAILURE: CNF for #{pretty_test_name_capitalized} Failed")
      end
      resp
      # TODO should we roll the image back to original version in an ensure? 
      # TODO Use the kubectl rollback to history command
    end
  end
end

desc "Test if the CNF can perform a rollback"
task "rollback" do |_, args|
  task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "rollback" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"

    container_names = config.cnf_config[:container_names]
    LOGGING.debug "container_names: #{container_names}"

    update_applied = true
    rollout_status = true
    rollback_status = true 
    version_change_applied = true 

    unless container_names
      puts "Please add a container names set of entries into your cnf-conformance.yml".colorize(:red) 
      update_applied = false
    end

    task_response = update_applied && CNFManager.workload_resource_test(args, config) do |resource, container, initialized|


        image_name = container.as_h["name"]
        image_tag = container.as_h["image"].as_s.split(":")[0]

        VERBOSE_LOGGING.debug "image_name: #{image_name}" if check_verbose(args)
        VERBOSE_LOGGING.debug "rollback: setting new version" if check_verbose(args)
        #do_update = `kubectl set image deployment/coredns-coredns coredns=coredns/coredns:latest --record`

        version_change_applied = false 
        config_container = container_names.find{|x| x["name"] == image_name } if container_names
        if config_container
          rollback_from_tag = config_container["rollback_from_tag"]

          if rollback_from_tag == image_tag
            fail_msg = "✖️  FAILURE: please specify a different version than the helm chart default image.tag for 'rollback_from_tag' "
            puts fail_msg.colorize(:red)
            version_change_applied=false
          end

          version_change_applied = KubectlClient::Set.image(resource["name"], 
                                                            image_name, 
                                                            image_tag, 
                                                            rollback_from_tag) 
        end

        VERBOSE_LOGGING.debug "change successful? #{version_change_applied}" if check_verbose(args)

        VERBOSE_LOGGING.debug "rollback: checking status new version" if check_verbose(args)
        rollout_status = KubectlClient::Rollout.status(resource["name"])
        if  rollout_status == false
          puts "Rolling update failed on resource: #{resource["name"]} and container: #{container.as_h["name"].as_s}".colorize(:red)
        end

        # https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-to-a-previous-revision
        VERBOSE_LOGGING.debug "rollback: rolling back to old version" if check_verbose(args)
        rollback_status = KubectlClient::Rollout.undo(resource["name"])

    end


    if task_response && version_change_applied && rollout_status && rollback_status
      upsert_passed_task("rollback","✔️  PASSED: CNF Rollback Passed" )
    else
      upsert_failed_task("rollback", "✖️  FAILURE: CNF Rollback Failed")
    end
  end
end

desc "Does the CNF use NodePort"
task "nodeport_not_used", ["retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "nodeport_not_used" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"
    release_name = config.cnf_config[:release_name]
    service_name  = config.cnf_config[:service_name]
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    #TODO loop through all resources that have a kind of service
    if File.exists?("#{destination_cnf_dir}/service.yml")
      service = Totem.from_file "#{destination_cnf_dir}/service.yml"
      VERBOSE_LOGGING.debug service.inspect if check_verbose(args)
      service_type = service.get("spec").as_h["type"].as_s
      VERBOSE_LOGGING.debug service_type if check_verbose(args)
      if service_type == "NodePort" 
        upsert_failed_task("nodeport_not_used", "✖️  FAILURE: NodePort is being used")
      else
        upsert_passed_task("nodeport_not_used", "✔️  PASSED: NodePort is not used")
      end
    else
      upsert_passed_task("nodeport_not_used", "✔️  PASSED: NodePort is not used")
    end
  end
end

desc "Does the CNF have hardcoded IPs in the K8s resource configuration"
task "hardcoded_ip_addresses_in_k8s_runtime_configuration" do |_, args|
  task_response = task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "Task Name: hardcoded_ip_addresses_in_k8s_runtime_configuration" if check_verbose(args)
    # config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    helm_chart = config.cnf_config[:helm_chart]
    helm_directory = config.cnf_config[:helm_directory]
    release_name = config.cnf_config[:release_name]
    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
    current_dir = FileUtils.pwd
    helm = CNFSingleton.helm
    VERBOSE_LOGGING.info "Helm Path: #{helm}" if check_verbose(args)

    create_namespace = `kubectl create namespace hardcoded-ip-test`
    unless helm_chart.empty?
      helm_install = `#{helm} install --namespace hardcoded-ip-test hardcoded-ip-test #{helm_chart} --dry-run --debug > #{destination_cnf_dir}/helm_chart.yml`
      VERBOSE_LOGGING.info "helm_chart: #{helm_chart}" if check_verbose(args)
    else
      helm_install = `#{helm} install --namespace hardcoded-ip-test hardcoded-ip-test #{destination_cnf_dir}/#{helm_directory} --dry-run --debug > #{destination_cnf_dir}/helm_chart.yml`
      VERBOSE_LOGGING.info "helm_directory: #{helm_directory}" if check_verbose(args)
    end

    ip_search = File.read_lines("#{destination_cnf_dir}/helm_chart.yml").take_while{|x| x.match(/NOTES:/) == nil}.reduce([] of String){|acc, x| x.match(/([0-9]{1,3}[\.]){3}[0-9]{1,3}/) && x.match(/([0-9]{1,3}[\.]){3}[0-9]{1,3}/).try &.[0] != "0.0.0.0" ? acc << x : acc}
    VERBOSE_LOGGING.info "IPs: #{ip_search}" if check_verbose(args)

    if ip_search.empty? 
      upsert_passed_task("hardcoded_ip_addresses_in_k8s_runtime_configuration", "✔️  PASSED: No hard-coded IP addresses found in the runtime K8s configuration")
    else
      upsert_failed_task("hardcoded_ip_addresses_in_k8s_runtime_configuration", "✖️  FAILURE: Hard-coded IP addresses found in the runtime K8s configuration")
    end
    delete_namespace = `kubectl delete namespace hardcoded-ip-test --force --grace-period 0 2>&1 >/dev/null`

  end
end

# https://www.cloudytuts.com/tutorials/kubernetes/how-to-create-immutable-configmaps-and-secrets/
def configmap_template
  <<-TEMPLATE
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: myapp
  immutable: true
  data:
    api.server: {{ test_url }}
  TEMPLATE
end

desc "Does the CNF use immutable configmaps?"
task "immutable_configmap", ["retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "immutable_configmap" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"

    destination_cnf_dir = config.cnf_config[:destination_cnf_dir]

    # https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
    # https://github.com/cncf/cnf-conformance/issues/508#issuecomment-758438413

    test_config_map_filename = "#{destination_cnf_dir}/test_config_map.yml";

    template = Crinja.render(configmap_template, { "test_url" => "doesnt_matter" })
    LOGGING.debug "test immutable_configmap template: #{template}"
    test_config_map_create = `echo "#{template}" > "#{test_config_map_filename}"`
    VERBOSE_LOGGING.debug "#{test_config_map_create}" if check_verbose(args)

    KubectlClient::Apply.file(test_config_map_filename)

    # now we change then apply again

    template = Crinja.render(configmap_template, { "test_url" => "doesnt_matter_again" })
    LOGGING.debug "test immutable_configmap change template: #{template}"
    test_config_map_create = `echo "#{template}" > "#{test_config_map_filename}"`
    VERBOSE_LOGGING.debug "#{test_config_map_create}" if check_verbose(args)

    # if the reapply with a change succedes immmutable configmaps is NOT enabled
    if KubectlClient::Apply.file(test_config_map_filename) == 0
      resp = "✖️  FAILURE: immmutable configmaps are not enabled in this k8s cluster.".colorize(:red)
        upsert_failed_task("immutable_configmap", resp)
    end

    # cleanup test configmap
    KubectlClient::Delete.file(test_config_map_filename) 

    # re: feature gates: https://github.com/cncf/cnf-conformance/issues/508#issuecomment-758388434
    config_maps_json = KubectlClient::Get.configmaps

    if config_maps_json["items"].as_a.select {|x| x["immutable"]? && x["immutable"] === true}.size === config_maps_json["items"].as_a.size
        resp = "✔️  PASSED: All configmaps immutable".colorize(:green)
        upsert_passed_task("immutable_configmap", resp)
    else
      resp = "✖️  FAILURE: Found mutable configmap(s)".colorize(:red)
        upsert_failed_task("immutable_configmap", resp)
    end
  end
end