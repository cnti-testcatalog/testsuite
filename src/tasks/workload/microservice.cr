# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"
# require "../utils/docker_client.cr"
require "docker_client"
require "halite"
require "totem"

desc "The CNF test suite checks to see if CNFs follows microservice principles"
task "microservice", ["reasonable_image_size", "reasonable_startup_time", "single_process_type", "service_discovery", "shared_database"] do |_, args|
  stdout_score("microservice")
end

REASONABLE_STARTUP_BUFFER = 10.0

desc "Does the CNF have a reasonable startup time (< 30 seconds)?"
task "shared_database", ["install_cluster_tools"] do |_, args|
  LOGGING.info "Running shared_database test"
  CNFManager::Task.task_runner(args) do |args, config|
    # todo loop through local resources and see if db match found
    db_match = Mariadb.match
    Log.info { "DB Digest: #{db_match[:digest]}" }
    #todo find offical database ip
    db_pods = KubectlClient::Get.pods_by_digest(db_match[:digest])
    Log.info { "DB Pods: #{db_pods}" }

    db_pod_ips = [] of Array(JSON::Any)
    pod_statuses = db_pods.map { |i|
      db_pod_ips << i.dig("status", "podIPs").as_a
      {
        "statuses" => i.dig("status", "containerStatuses"),
       "nodeName" => i.dig("spec", "nodeName")}
    }.compact
    db_pod_ips = db_pod_ips.compact.flatten
    Log.info { "Pod Statuses: #{pod_statuses}" }
    Log.info { "db_pod_ips: #{db_pod_ips}" }

    database_container_statuses = pod_statuses.map do |statuses| 
      # filterd_statuses : Array(JSON::Any)
      filterd_statuses = statuses["statuses"].as_a.select{ |x|
        x && x.dig("imageID").as_s.includes?("#{db_match[:digest]}")
      }
      resp : NamedTuple("nodeName": String, "ids" : Array(String)) = 
      {
        # this is the worst part of crystal
        "nodeName": statuses["nodeName"].as_s, 
       "ids": filterd_statuses.map{ |s| s.dig("containerID").as_s.gsub("containerd://", "")[0..12]}
      }

      resp
    end.compact.flatten

    resource_pod_ips = [] of Array(JSON::Any)
    # CNFManager.workload_resource_test(args, config) do |resource_name, container, initialized|
    resource_ymls = CNFManager.cnf_workload_resources(args, config) { |resource| resource }
    resource_names = Helm.workload_resource_kind_names(resource_ymls)
    # resource_names.each do |resource_name|
    #   resource = KubectlClient::Get.resource(resource_name[:kind], resource_name[:name])
    #   pods = KubectlClient::Get.pods_by_resource(resource)
    #   resource_pod_ips << pods.map { |pod|
    #     pod.dig("status", "podIPs").as_a
    #   }.flatten.compact
    # end
    # cnf_ips = resource_pod_ips.compact.flatten
    # Log.info { "cnf IPs: #{cnf_ips}"}

    cnf_services = KubectlClient::Get.services
    # cnf_services = resource_names.map { |resource_name|
    #   case resource_name[:kind].as_s.downcase
    #   when "service"
    #     resource = KubectlClient::Get.resource(resource_name[:kind], resource_name[:name])
    #   end
    # }.compact 

    #todo get all pod_ips by first cnf service that is not the database service
    service_pod_ips = [] of Array(NamedTuple(service_group_id: Int32, pod_ips: Array(JSON::Any)))
    cnf_services["items"].as_a.each_with_index do |cnf_service, index|
      service_pods = KubectlClient::Get.pods_by_service(cnf_service)
      if service_pods
        service_pod_ips << service_pods.map { |pod|
          {
            service_group_id: index,
            pod_ips: pod.dig("status", "podIPs").as_a.select{|ip|
              db_pod_ips.select{|dbip| dbip["ip"].as_s != ip["ip"].as_s}
            }
          }

        }.flatten.compact
      end
    end

    service_pod_ips = service_pod_ips.compact.flatten
    Log.info { "service_pod_ips: #{service_pod_ips}"}

    integrated_database_found = false
    Log.info { "Container Statuses: #{database_container_statuses}" }
    database_container_statuses.each do |status|
      Log.info { "Container Info: #{status}"}
      # get network information on the node for each database pod
      cluster_tools = ClusterTools.pod_by_node("#{status["nodeName"]}")
      Log.info { "Container Tools Pod: #{cluster_tools}"}
      pids = status["ids"].map do |id| 
        inspect = KubectlClient.exec("#{cluster_tools} -t -- crictl inspect #{id}", namespace: TESTSUITE_NAMESPACE)
        pid = JSON.parse(inspect[:output]).dig("info", "pid")
        Log.info { "Container PID: #{pid}"}
        # get multiple call for a larger sample
        parsed_netstat = (1..10).map {
          sleep 10
          netstat = KubectlClient.exec("#{cluster_tools} -t -- nsenter -t #{pid} -n netstat", namespace: TESTSUITE_NAMESPACE)
          Log.info { "Container Netstat: #{netstat}"}
          Netstat.parse(netstat[:output])
        }.flatten.compact
        # Log.info { "Container Netstat: #{netstat}"}
        # parsed_netstat = Netstat.parse(netstat[:output])
        # Log.info { "Container Netstat: #{parsed_netstat}"}
        #todo filter for 3306 in local_address
        filtered_local_address = parsed_netstat.reduce([] of NamedTuple(proto: String, 
                                                                         recv: String, 
                                                                         send: String, 
                                                                         local_address: String, 
                                                                         foreign_address: String, 
                                                                         state: String)) do |acc,x|
          if x[:local_address].includes?("3306")
            acc << x
          else
            acc
          end
         end
        Log.info { "filtered_local_address: #{filtered_local_address}"}
        #todo filter for ips that belong to the cnf
        filtered_foreign_addresses = filtered_local_address.reduce([] of NamedTuple(proto: String, 
                                                                         recv: String, 
                                                                         send: String, 
                                                                         local_address: String, 
                                                                         foreign_address: String, 
                                                                         state: String)) do |acc,x|



         ignored_ip = service_pod_ips[0]["pod_ips"].find{|i| x[:foreign_address].includes?(i["ip"].as_s)}
         if ignored_ip 
           Log.info { "dont add: #{x[:foreign_address]}"}
           acc
         else
           Log.info { " add: #{x[:foreign_address]}"}
           acc << x
         end
         acc
        end
        Log.info { "filtered_foreign_addresses: #{filtered_foreign_addresses}"}
        #todo if count on uniq foreign ip addresses > 1 then fail
        # only count violators if they are part of any service, cluster wide
        violators = service_pod_ips.reduce([] of Array(JSON::Any)) do |acc, service_group|
          acc << service_group["pod_ips"].select do |spip| 
            Log.info { " service ip: #{spip["ip"].as_s}"}
            filtered_foreign_addresses.find do |f|
              f[:foreign_address].includes?(spip["ip"].as_s)
            end
          end 
        end
        violators = violators.flatten.compact
        if violators.size > 1
        # if filtered_foreign_address.size > 1
          puts "Found multiple pod ips from different services that connect to the same database: #{violators}".colorize(:red)
          integrated_database_found = true 
        end
      end
    end

    failed_emoji = "(ভ_ভ) ރ 💾"
    passed_emoji = "🖥️  💾"
    if integrated_database_found 
      upsert_failed_task("shared_database", "✖️  FAILED: Found a shared database #{failed_emoji}")
    else
      upsert_passed_task("shared_database", "✔️  PASSED: No shared database found #{passed_emoji}")
    end
  end
end

desc "Does the CNF have a reasonable startup time (< 30 seconds)?"
task "reasonable_startup_time" do |_, args|
  LOGGING.info "Running reasonable_startup_time test"
  CNFManager::Task.task_runner(args) do |args, config|
    VERBOSE_LOGGING.info "reasonable_startup_time" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config.cnf_config}"

    yml_file_path = config.cnf_config[:yml_file_path]
    helm_chart = config.cnf_config[:helm_chart]
    helm_directory = config.cnf_config[:helm_directory]
    release_name = config.cnf_config[:release_name]
    install_method = config.cnf_config[:install_method]

    current_dir = FileUtils.pwd
    helm = BinarySingleton.helm
    VERBOSE_LOGGING.info helm if check_verbose(args)


    configmap = KubectlClient::Get.configmap("cnf-testsuite-#{release_name}-startup-information")
    #TODO check if json is empty
    startup_time = configmap["data"].as_h["startup_time"].as_s

    emoji_fast="🚀"
    emoji_slow="🐢"
    # Correlation for a slow box vs a fast box 
    # sysbench base fast machine (disk), time in ms 0.16
    # sysbench base slow machine (disk), time in ms 6.55
    # percentage 0.16 is 2.44% of 6.55
    # How much more is 6.55 than 0.16? (0.16 - 6.55) / 0.16 * 100 = 3993.75%
    # startup time fast machine: 21 seconds
    # startup slow machine: 34 seconds
    # how much more is 34 seconds than 21 seconds? (21 - 34) / 21 * 100 = 61.90%
    # app seconds set 1: 21, set 2: 34
    # disk miliseconds set 1: .16 set 2: 6.55
    # get the mean of app seconds (x)
    #   (sum all: 55, count number of sets: 2, divide sum by count: 27.5)
    # get the mean of disk milliseconds (y)
    #   (sum all: 6.71, count number of sets: 2, divide sum by count: 3.35)
    # Subtract the mean of x from every x value (call them "a")
    # set 1: 6.5 
    # set 2: -6.5 
    # and subtract the mean of y from every y value (call them "b")
    # set 1: 3.19
    # set 2: -3.2
    # calculate: ab, a2 and b2 for every value
    # set 1: 20.735, 42.25, 42.25
    # set 2: 20.8, 10.17, 10.24
    # Sum up ab, sum up a2 and sum up b2
    # 41.535, 52.42, 52.49
    # Divide the sum of ab by the square root of [(sum of a2) × (sum of b2)]
    # (sum of a2) × (sum of b2) = 2751.5258
    # square root of 2751.5258 = 52.4549
    # divide sum of ab by sqrt = 41.535 / 52.4549 = .7918
    # example
    # sysbench returns a 5.55 disk millisecond result
    # disk millisecond has a pearson correlation of .79 to app seconds
    # 
    # Regression for predication based on slow and fast box disk times
    # regression = ŷ = bX + a
    # b = 2.02641
    # a = 20.72663

    resp = K8sInstrumentation.disk_speed
    if resp["95th percentile"]?
        disk_speed = resp["95th percentile"].to_f
      startup_time_limit = ((0.30593 * disk_speed) + 21.9162 + REASONABLE_STARTUP_BUFFER).round.to_i
    else
      startup_time_limit = 30
    end
    # if ENV["CRYSTAL_ENV"]? == "TEST"
    #   startup_time_limit = 35 
    #   LOGGING.info "startup_time_limit TEST mode: #{startup_time_limit}"
    # end
    LOGGING.info "startup_time_limit: #{startup_time_limit}"
    LOGGING.info "startup_time: #{startup_time.to_i}"

    if startup_time.to_i <= startup_time_limit
      upsert_passed_task("reasonable_startup_time", "✔️  PASSED: CNF had a reasonable startup time #{emoji_fast}")
    else
      upsert_failed_task("reasonable_startup_time", "✖️  FAILED: CNF had a startup time of #{startup_time} seconds #{emoji_slow}")
    end

  end
end

desc "Does the CNF have a reasonable container image size (< 5GB)?"
task "reasonable_image_size" do |_, args|
  unless Dockerd.install
    upsert_skipped_task("reasonable_image_size", "✖️  SKIPPED: Skipping reasonable_image_size: Dockerd tool failed to install")
    next
  end
  CNFManager::Task.task_runner(args) do |args,config|
    VERBOSE_LOGGING.info "reasonable_image_size" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|

      yml_file_path = config.cnf_config[:yml_file_path]

      if resource["kind"].downcase == "deployment" ||
          resource["kind"].downcase == "statefulset" ||
          resource["kind"].downcase == "pod" ||
          resource["kind"].downcase == "replicaset"
				test_passed = true

				fqdn_image = container.as_h["image"].as_s
        # parsed_image = DockerClient.parse_image(fqdn_image)

        image_pull_secrets = KubectlClient::Get.resource(resource[:kind], resource[:name]).dig?("spec", "template", "spec", "imagePullSecrets")
        if image_pull_secrets
          auths = image_pull_secrets.as_a.map { |secret|
            puts secret["name"]
            secret_data = KubectlClient::Get.resource("Secret", "#{secret["name"]}").dig?("data")
            if secret_data
              dockerconfigjson = Base64.decode_string("#{secret_data[".dockerconfigjson"]}")
              dockerconfigjson.gsub(%({"auths":{),"")[0..-3]
              # parsed_dockerconfigjson = JSON.parse(dockerconfigjson)
              # parsed_dockerconfigjson["auths"].to_json.gsub("{","").gsub("}", "")
            else
              # JSON.parse(%({}))
              ""
            end
          }
          if auths
            str_auths = %({"auths":{#{auths.reduce("") { | acc, x|
            acc + x.to_s + ","
          }[0..-2]}}})
            puts "str_auths: #{str_auths}"
          end
          File.write("#{yml_file_path}/config.json", str_auths)
          Dockerd.exec("mkdir -p /root/.docker/")
          KubectlClient.cp("#{yml_file_path}/config.json #{TESTSUITE_NAMESPACE}/dockerd:/root/.docker/config.json")
        end

        Log.info { "FQDN of the docker image: #{fqdn_image}" }
        Dockerd.exec("docker pull #{fqdn_image}")
        Dockerd.exec("docker save #{fqdn_image} -o /tmp/image.tar")
        Dockerd.exec("gzip -f /tmp/image.tar")
        exec_resp = Dockerd.exec("wc -c /tmp/image.tar.gz | awk '{print$1}'")
        compressed_size = exec_resp[:output]
        # TODO strip out secret from under auths, save in array
        # TODO make a new auths array, assign previous array into auths array
        # TODO save auths array to a file
        Log.info { "compressed_size: #{fqdn_image} = '#{compressed_size.to_s}'" }
        max_size = 5_000_000_000
        if ENV["CRYSTAL_ENV"]? == "TEST"
           Log.info { "Using Test Mode max_size" }
           max_size = 16_000_000
        end

        begin
          unless compressed_size.to_s.to_i64 < max_size
            puts "resource: #{resource} and container: #{fqdn_image} was more than #{max_size}".colorize(:red)
            test_passed=false
          end
        rescue ex
          Log.error { "invalid compressed_size: #{fqdn_image} = '#{compressed_size.to_s}', #{ex.message}".colorize(:red) }
          test_passed = false
        end
      else
        test_passed = true
      end
      test_passed
    end

    emoji_image_size="⚖️👀"
    emoji_small="🐜"
    emoji_big="🦖"

    if task_response
      upsert_passed_task("reasonable_image_size", "✔️  PASSED: Image size is good #{emoji_small} #{emoji_image_size}")
    else
      upsert_failed_task("reasonable_image_size", "✖️  FAILED: Image size too large #{emoji_big} #{emoji_image_size}")
    end
  end
end

desc "Do the containers in a pod have only one process type?"
task "single_process_type" do |_, args|
  CNFManager::Task.task_runner(args) do |args,config|
    VERBOSE_LOGGING.info "single_process_type" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"
    fail_msgs = [] of String
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
      kind = resource["kind"].downcase
      case kind 
      when  "deployment","statefulset","pod","replicaset", "daemonset"
        resource_yaml = KubectlClient::Get.resource(resource[:kind], resource[:name])
        pods = KubectlClient::Get.pods_by_resource(resource_yaml)
       
        containers = KubectlClient::Get.resource_containers(kind, resource[:name]) 
        pods.map do |pod|
          pod_name = pod.dig("metadata", "name")
          containers.as_a.map do |container|
            container_name = container.dig("name")
            previous_process_type = "initial_name"
            statuses = KernelIntrospection::K8s.status_by_proc(pod_name, container_name)
            statuses.map do |status|
              LOGGING.debug "status: #{status}"
              LOGGING.info "status name: #{status["cmdline"]}"
              LOGGING.info "previous status name: #{previous_process_type}"
              # Fail if more than one process type
              if status["Name"] != previous_process_type && 
                  previous_process_type != "initial_name"
                fail_msg = "resource: #{resource}, pod #{pod_name} and container: #{container_name} has more than one process type (#{statuses.map{|x|x["cmdline"]?}.compact.uniq.join(", ")})"
                unless fail_msgs.find{|x| x== fail_msg}
                  puts fail_msg.colorize(:red)
                  fail_msgs << fail_msg
                end
                test_passed=false
              end
              previous_process_type = status["cmdline"]
            end
          end
        end
        test_passed
      end
    end
    emoji_image_size="⚖️👀"
    emoji_small="🐜"
    emoji_big="🦖"

    if task_response
      upsert_passed_task("single_process_type", "✔️  PASSED: Only one process type used #{emoji_small} #{emoji_image_size}")
    else
      upsert_failed_task("single_process_type", "✖️  FAILED: More than one process type used #{emoji_big} #{emoji_image_size}")
    end
  end
end

desc "Are any of the containers exposed as a service?"
task "service_discovery" do |_, args|
  CNFManager::Task.task_runner(args) do |args,config|
    Log.for("verbose").info { "service_discovery" } if check_verbose(args)

    # Get all resources for the CNF
    namespace = CNFManager.namespace_from_parameters(CNFManager.install_parameters(config))
    resource_ymls = CNFManager.cnf_workload_resources(args, config) { |resource| resource }
    resources = Helm.workload_resource_kind_names(resource_ymls)

    # Collect service names from the CNF resource list
    cnf_service_names = [] of String
    resources.each do |resource|
      case resource[:kind].downcase
      when "service"
        cnf_service_names.push(resource[:name])
      end
    end

    # Get all the pods in the cluster
    pods = KubectlClient::Get.pods().dig("items").as_a

    # Get pods for the services in the CNF based on the labels
    test_passed = false
    KubectlClient::Get.services().dig("items").as_a.each do |service_info|
      # Only check for pods for services that are defined by the CNF
      service_name = service_info["metadata"]["name"]
      next unless cnf_service_names.includes?(service_name)

      # Some services may not have selectors defined. Example: service/kubernetes
      pod_selector = service_info.dig?("spec", "selector")
      next unless pod_selector

      # Fetch matching pods for the CNF
      # If any service has a matching pod, then mark test as passed
      matching_pods = KubectlClient::Get.pods_by_labels(pods, pod_selector.as_h)
      if matching_pods.size > 0
        Log.debug { "Matching pods for service #{service_name}: #{matching_pods.inspect}" }
        test_passed = true
      end
    end

    emoji_image_size="⚖️👀"
    emoji_small="🐜"
    emoji_big="🦖"

    if test_passed
      upsert_passed_task("service_discovery", "✔️  PASSED: Some containers exposed as a service #{emoji_small} #{emoji_image_size}")
    else
      upsert_failed_task("service_discovery", "✖️  FAILED: No containers exposed as a service #{emoji_big} #{emoji_image_size}")
    end
  end
end
