require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils.cr"

desc "The CNF conformance suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s kubectl"
task "scaling", ["increase_decrease_capacity"] do |t, args|
  puts "scaling args.raw: #{args.raw}" if check_verbose(args)
  puts "scaling args.named: #{args.named}" if check_verbose(args)
  # t.invoke("increase_decrease_capacity", args)
end

desc "Test increasing/decreasing capacity"
task "increase_decrease_capacity" do |_, args|
  #TODO Document all arguments
  #TODO check if container exists
  #TODO Get a list of all containers and loop through
  puts "increase_decrease_capacity args.raw: #{args.raw}" if check_verbose(args)
  puts "increase_decrease_capacity args.named: #{args.named}" if check_verbose(args)
  response = String::Builder.new
  if args.named.keys.includes? "replicas"
    replica_count = args.named["replicas"]
  else
    replica_count = "10"
  end
  if args.named.keys.includes? "wait_count"
    wait_count = args.named["wait_count"]
  else
    wait_count = "10"
  end
  if args.size > 0
    #TODO get name of pod from config file
    increase = `kubectl scale deployment.v1.apps/#{args[0].as(String)} --replicas=#{replica_count}`
    puts "#{increase}" if check_verbose(args) 
    ready_replicas = "" 
    second_count = 0
    until ready_replicas == replica_count || second_count > wait_count.to_i
      puts "secound_count wait_count #{second_count} #{wait_count}" if check_verbose(args)
      puts "ready_replicas #{ready_replicas}" if check_verbose(args)
      sleep 1
      second_count = second_count + 1 
      ready_replicas = `kubectl get deployments #{args[0].as(String)} -o=jsonpath='{.status.readyReplicas}'`
      puts "#{ready_replicas}" if check_verbose(args)
    end
    if ready_replicas == replica_count
      puts "PASSED: Replicas changed to #{replica_count}".colorize(:green)
    else
      puts "FAILURE: Replicas did not reach #{replica_count}".colorize(:red)
    end
  end
end


