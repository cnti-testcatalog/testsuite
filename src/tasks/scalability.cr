require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "The CNF conformance suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s kubectl"
task "scalability", ["increase_decrease_capacity"] do |t, args|
  puts "scaling args.raw: #{args.raw}" if check_verbose(args)
  puts "scaling args.named: #{args.named}" if check_verbose(args)
  # t.invoke("increase_decrease_capacity", args)
end

desc "Test increasing/decreasing capacity"
task "increase_decrease_capacity", ["increase_capacity", "decrease_capacity"] do |t, args|
end


desc "Test increasing capacity by setting replicas to 1 and then increasing to 3"
task "increase_capacity" do |_, args|
  begin

    emoji_increase_capacity="📦📈"

    target_replicas = "3"
    base_replicas = "1"
    final_count = change_capacity(base_replicas, target_replicas, args)
    if target_replicas == final_count 
      upsert_passed_task("increase_capacity")
      puts "✔️  PASSED: Replicas increased to #{target_replicas} #{emoji_increase_capacity}".colorize(:green)
    else
      upsert_failed_task("increase_capacity")
      puts "✖️  FAILURE: Replicas did not reach #{target_replicas} #{emoji_increase_capacity}".colorize(:red)
    end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end

desc "Test decrease capacity by setting replicas to 3 and then decreasing to 1"
task "decrease_capacity" do |_, args|
  begin
    target_replicas = "1"
    base_replicas = "3"
    final_count = change_capacity(base_replicas, target_replicas, args)
    emoji_decrease_capacity="📦📉"

    if target_replicas == final_count 
      upsert_passed_task("decrease_capacity")
      puts "✔️  PASSED: Replicas decreased to #{target_replicas} #{emoji_decrease_capacity}".colorize(:green)
    else
      upsert_failed_task("decrease_capacity")
      puts "✖️  FAILURE: Replicas did not reach #{target_replicas} #{emoji_decrease_capacity}".colorize(:red)
    end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  end
end

def change_capacity(base_replicas, target_replica_count, args)
  puts "change_capacity" if check_verbose(args)
  puts "increase_capacity args.raw: #{args.raw}" if check_verbose(args)
  puts "increase_capacity args.named: #{args.named}" if check_verbose(args)
  puts "base replicas: #{base_replicas}" if check_verbose(args)

  # Parse the cnf-conformance.yml
  config = cnf_conformance_yml

  initialization_time = base_replicas.to_i * 10
  if args.named.keys.includes? "deployment_name"
    deployment_name = args.named["deployment_name"]
  else
    deployment_name = config.get("deployment_name").as_s 
  end
  puts "deployment_name: #{deployment_name}" if check_verbose(args)

  base = `kubectl scale deployment.v1.apps/#{deployment_name} --replicas=#{base_replicas}`
  puts "base: #{base}" if check_verbose(args) 
  initialized_count = wait_for_scaling(deployment_name, base_replicas, args)
  if initialized_count != base_replicas
    puts "deployment initialized to #{initialized_count} and could not be set to #{base_replicas}" if check_verbose(args)
  else
    puts "deployment initialized to #{initialized_count}" if check_verbose(args)
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
    puts "secound_count: #{second_count} wait_count: #{wait_count}" if check_verbose(args)
    puts "current_replicas before get deployments: #{current_replicas}" if check_verbose(args)
    sleep 1
    puts `echo $KUBECONFIG` if check_verbose(args)
    puts "Get deployments command: kubectl get deployments #{deployment_name} -o=jsonpath='{.status.readyReplicas}'" if check_verbose(args)
    current_replicas = `kubectl get deployments #{deployment_name} -o=jsonpath='{.status.readyReplicas}'`
    puts "current_replicas after get deployments: #{current_replicas.inspect}" if check_verbose(args)
    if current_replicas.to_i != previous_replicas.to_i
      second_count = 0
      previous_replicas = current_replicas
    end
    second_count = second_count + 1 
    puts "previous_replicas: #{previous_replicas}" if check_verbose(args)
    puts "current_replicas: #{current_replicas}" if check_verbose(args)
  end
  current_replicas
end 

