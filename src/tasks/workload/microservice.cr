# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"
require "../utils/docker_client.cr"
require "halite"
require "totem"

desc "The CNF test suite checks to see if CNFs follows microservice principles"
task "microservice", ["reasonable_image_size", "reasonable_startup_time", "single_process_type"] do |_, args|
  stdout_score("microservice")
end

desc "Does the CNF have a reasonable startup time (< 30 seconds)?"
task "reasonable_startup_time", ["install_cri_tools"] do |_, args|
  
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
    helm = CNFSingleton.helm
    VERBOSE_LOGGING.info helm if check_verbose(args)

    configmap = KubectlClient::Get.configmap("cnf-testsuite-#{release_name}-startup-information")
    #TODO check if json is empty
    startup_time = configmap["data"].as_h["startup_time"].as_s

    emoji_fast="🚀"
    emoji_slow="🐢"
    # todo depedency for cri tools
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
    # regression = ŷ = bX + a
    # b = 2.02641
    # a = 20.72663

    # todo get the disk milisecond speed
    # apply regression prediction
    # adjust seconds by speed


  
    startup_time_limit = 30
    # if ENV["CRYSTAL_ENV"]? == "TEST"
    #   startup_time_limit = 35 
    #   LOGGING.info "startup_time_limit TEST mode: #{startup_time_limit}"
    # end
    LOGGING.info "startup_time_limit: #{startup_time_limit}"
    LOGGING.info "startup_time: #{startup_time.to_i}"

    if startup_time.to_i < startup_time_limit
      upsert_passed_task("reasonable_startup_time", "✔️  PASSED: CNF had a reasonable startup time #{emoji_fast}")
    else
      upsert_failed_task("reasonable_startup_time", "✖️  FAILED: CNF had a startup time of #{startup_time} seconds #{emoji_slow}")
    end

  end
end

desc "Does the CNF have a reasonable container image size (< 5GB)?"
task "reasonable_image_size", ["install_dockerd"] do |_, args|
  unless check_dockerd
    upsert_skipped_task("reasonable_image_size", "✖️  SKIPPED: Skipping reasonable_image_size: Dockerd tool failed to install")
    next
  end
  CNFManager::Task.task_runner(args) do |args,config|
    VERBOSE_LOGGING.info "reasonable_image_size" if check_verbose(args)
    LOGGING.debug "cnf_config: #{config}"
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|

      yml_file_path = config.cnf_config[:yml_file_path]

      if resource["kind"].as_s.downcase == "deployment" ||
          resource["kind"].as_s.downcase == "statefulset" ||
          resource["kind"].as_s.downcase == "pod" ||
          resource["kind"].as_s.downcase == "replicaset"
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
          KubectlClient.exec("dockerd -ti -- mkdir -p /root/.docker/")
          KubectlClient.cp("#{yml_file_path}/config.json default/dockerd:/root/.docker/config.json")
        end


        KubectlClient.exec("dockerd -ti -- docker pull #{fqdn_image}")
        KubectlClient.exec("dockerd -ti -- docker save #{fqdn_image} -o /tmp/image.tar")
        KubectlClient.exec("dockerd -ti -- gzip -f /tmp/image.tar")
        exec_resp =  KubectlClient.exec("dockerd -ti -- wc -c /tmp/image.tar.gz | awk '{print$1}'")
        compressed_size = exec_resp[:output]
        # TODO strip out secret from under auths, save in array
        # TODO make a new auths array, assign previous array into auths array
        # TODO save auths array to a file
        LOGGING.info "compressed_size: #{fqdn_image} = '#{compressed_size.to_s}'"
        max_size = 5_000_000_000
        if ENV["CRYSTAL_ENV"]? == "TEST"
           LOGGING.info("Using Test Mode max_size")
           max_size = 16_000_000
        end

        begin
          unless compressed_size.to_s.to_i64 < max_size
            puts "resource: #{resource} and container: #{fqdn_image} was more than #{max_size}".colorize(:red)
            test_passed=false
          end
        rescue ex
          LOGGING.error "invalid compressed_size: #{fqdn_image} = '#{compressed_size.to_s}', #{ex.message}".colorize(:red)
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
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
      kind = resource["kind"].as_s.downcase
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
                puts "resource: #{resource}, pod #{pod_name} and container: #{container_name} has more than one process type (#{previous_process_type}, #{status["cmdline"]})".colorize(:red)
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


