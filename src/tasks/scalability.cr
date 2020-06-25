# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "The CNF conformance suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s kubectl"
task "scalability", ["increase_decrease_capacity"] do |t, args|
  LOGGING.info "scalability" if check_verbose(args)
  LOGGING.debug "scaling args.raw: #{args.raw}" if check_verbose(args)
  LOGGING.debug "scaling args.named: #{args.named}" if check_verbose(args)
  # t.invoke("increase_decrease_capacity", args)
  total = total_points("scalability")
  if total > 0
    puts "Scalability final score: #{total} of #{total_max_points("scalability")}".colorize(:green)
  else
    puts "Scalability final score: #{total} of #{total_max_points("scalability")}".colorize(:red)
  end
end

desc "Test increasing/decreasing capacity"
task "increase_decrease_capacity", ["increase_capacity", "decrease_capacity"] do |t, args|
  LOGGING.info "increase_decrease_capacity" if check_verbose(args)
end


desc "Test increasing capacity by setting replicas to 1 and then increasing to 3"
task "increase_capacity" do |_, args|
  task_runner(args) do |args|
    LOGGING.info "increase_capacity" if check_verbose(args)
    emoji_increase_capacity="📦📈"

    target_replicas = "3"
    base_replicas = "1"
    final_count = change_capacity(base_replicas, target_replicas, args)
    if target_replicas == final_count 
      upsert_passed_task("increase_capacity", "✔️  PASSED: Replicas increased to #{target_replicas} #{emoji_increase_capacity}")
    else
      upsert_failed_task("increase_capacity", "✖️  FAILURE: Replicas did not reach #{target_replicas} #{emoji_increase_capacity}")
    end
  end
end

desc "Test decrease capacity by setting replicas to 3 and then decreasing to 1"
task "decrease_capacity" do |_, args|
  task_runner(args) do |args|
    LOGGING.info "decrease_capacity" if check_verbose(args)
    target_replicas = "1"
    base_replicas = "3"
    final_count = change_capacity(base_replicas, target_replicas, args)
    emoji_decrease_capacity="📦📉"

    if target_replicas == final_count 
      upsert_passed_task("decrease_capacity", "✔️  PASSED: Replicas decreased to #{target_replicas} #{emoji_decrease_capacity}")
    else
      upsert_failed_task("decrease_capacity", "✖️  FAILURE: Replicas did not reach #{target_replicas} #{emoji_decrease_capacity}")
    end
  end
end

def change_capacity(base_replicas, target_replica_count, args)
  LOGGING.info "change_capacity" if check_verbose(args)
  LOGGING.debug "increase_capacity args.raw: #{args.raw}" if check_verbose(args)
  LOGGING.debug "increase_capacity args.named: #{args.named}" if check_verbose(args)
  LOGGING.info "base replicas: #{base_replicas}" if check_verbose(args)

  # Parse the cnf-conformance.yml
  # config = cnf_conformance_yml
  config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))

  initialization_time = base_replicas.to_i * 10
  if args.named.keys.includes? "deployment_name"
    deployment_name = args.named["deployment_name"]
  else
    deployment_name = config.get("deployment_name").as_s 
  end
  LOGGING.info "deployment_name: #{deployment_name}" if check_verbose(args)

  base = `kubectl scale deployment.v1.apps/#{deployment_name} --replicas=#{base_replicas}`
  LOGGING.info "base: #{base}" if check_verbose(args) 
  initialized_count = wait_for_scaling(deployment_name, base_replicas, args)
  if initialized_count != base_replicas
    LOGGING.info "deployment initialized to #{initialized_count} and could not be set to #{base_replicas}" if check_verbose(args)
  else
    LOGGING.info "deployment initialized to #{initialized_count}" if check_verbose(args)
  end

  increase = `kubectl scale deployment.v1.apps/#{deployment_name} --replicas=#{target_replica_count}`
  current_replicas = wait_for_scaling(deployment_name, target_replica_count, args)
  current_replicas
end

def wait_for_scaling(deployment_name, target_replica_count, args)
  puts "target_replica_count: #{target_replica_count}" if check_verbose(args)
  if args.named.keys.includes? "wait_count"
    wait_count_value = args.named["wait_count"]
  else
    wait_count_value = "30"
  end
  wait_count = wait_count_value.to_i
  second_count = 0
  current_replicas = "0"
  previous_replicas = `kubectl get deployments #{deployment_name} -o=jsonpath='{.status.readyReplicas}'`
  until current_replicas == target_replica_count || second_count > wait_count
    LOGGING.debug "secound_count: #{second_count} wait_count: #{wait_count}" if check_verbose(args)
    LOGGING.info "current_replicas before get deployments: #{current_replicas}" if check_verbose(args)
    sleep 1
    LOGGING.debug `echo $KUBECONFIG` if check_verbose(args)
    LOGGING.info "Get deployments command: kubectl get deployments #{deployment_name} -o=jsonpath='{.status.readyReplicas}'" if check_verbose(args)
    current_replicas = `kubectl get deployments #{deployment_name} -o=jsonpath='{.status.readyReplicas}'`
    LOGGING.info "current_replicas after get deployments: #{current_replicas.inspect}" if check_verbose(args)

    if current_replicas.empty?
      current_replicas = "0"
      previous_replicas = "0"
    end

    if current_replicas.to_i != previous_replicas.to_i
      second_count = 0
      previous_replicas = current_replicas
    end
    second_count = second_count + 1 
    LOGGING.info "previous_replicas: #{previous_replicas}" if check_verbose(args)
    LOGGING.info "current_replicas: #{current_replicas}" if check_verbose(args)
  end
  current_replicas
end 

