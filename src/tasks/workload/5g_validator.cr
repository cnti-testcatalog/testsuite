# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "Test if a 5G core has SMF/UPF heartbeat"
task "smf_upf_core_validator" do |t, args|
  CNFManager::Task.task_runner(args) do |args, config|
    task_start_time = Time.utc
    testsuite_task = "smf_upf_core_validator"
    Log.for(testsuite_task).info { "Starting test" }
    args.named["reslience_tests"]="pod_network_latency, pod_delete"
    t.invoke("smf_upf_heartbeat", args)
  end
end

desc "Test if a 5G core has SMF/UPF heartbeat"
task "smf_upf_heartbeat" do |t, args|
  CNFManager::Task.task_runner(args) do |args, config|
    task_start_time = Time.utc
    testsuite_task = "smf_upf_heartbeat"
    Log.for(testsuite_task).info { "Starting test" }
    Log.for(testsuite_task).info { "named args: #{args.named}" }
    baseline_count : Int32 | Float64 | String | Nil
    if args.named["baseline_count"]?
      baseline_count = args.named["baseline_count"].to_i
    else
      baseline_count = nil
    end

    Log.debug { "cnf_config: #{config}" }
    suci_found : Bool | Nil
    smf = config.cnf_config[:smf_label]? 
    upf = config.cnf_config[:upf_label]? 
    Log.info { "smf: #{smf}" }
    Log.info { "upf: #{upf}" }
    smf_key : String  = ""
    smf_value : String = ""
    smf_key = config.cnf_config[:smf_label].split("=").first if smf
    smf_value = config.cnf_config[:smf_label].split("=").last if upf

    if smf && upf 

      #todo document 3gpp standard for heartbeat
      command = "-ni any -Y 'pfcp.msg_type == 1 or pfcp.msg_type == 2' -T json"

      #Baseline 
      unless baseline_count
        tshark_log_name = K8sTshark.log_of_tshark_by_label(command, smf_key, smf_value, duration="120")
        if tshark_log_name && 
            !tshark_log_name.empty? && 
            (tshark_log_name =~ /not found/) == nil
          scan = K8sTshark.regex_tshark_log_scan(/"pfcp\.msg_type": "(1|2)"/, tshark_log_name) 
          if scan
            baseline_count = scan.size
            Log.info { "Baseline matches: #{baseline_count}" }
          end
        end
      end

      #todo accept list of resilience tests
      #todo loop through all resilience tests
      #todo accumulate results (true/false) from loop and if false exits fail test
      #Chaos Matches
      sync_channel = Channel(Nil).new
      spawn do
        Log.info { "before invoke of pod delete" }
        args.named["pod_labels"]="#{smf},#{upf}"
   #     t.invoke("pod_delete", args)
        t.invoke("pod_network_latency", args)
        Log.info { "after invoke of pod delete" }
        sync_channel.send(nil)
      end
      Log.info { "Main pod delete thread continuing" }


      tshark_log_name = K8sTshark.log_of_tshark_by_label(command, smf_key, smf_value, duration="120")
      if tshark_log_name && 
          !tshark_log_name.empty? && 
          (tshark_log_name =~ /not found/) == nil

        Log.info { "TShark Log File: #{tshark_log_name}" }
        scan = K8sTshark.regex_tshark_log_scan(/"pfcp\.msg_type": "(1|2)"/, tshark_log_name) 
        if scan
          chaos_count = scan.size
          Log.info { "Chaos Matches: #{chaos_count}" }
        end
      end

      Log.info { "before pod delete receive" }
      sync_channel.receive
      Log.info { "after pod delete receive" }

      Log.info { "Chaos Matches: #{chaos_count}" }
      Log.info { "Baseline matches: #{baseline_count}" }

      if chaos_count && baseline_count
        if chaos_count.to_i >= baseline_count.to_i * 0.5 
          #todo inject current resilienct test name in messages
          Log.info { "Chaos service degradation is less than 50%. Passing" }
          heartbeat_found = true
        else
          #todo inject current resilienct test name in messages
          Log.info { "Chaos service degradation is more than 50%. Failing" }
          heartbeat_found = false
        end
      else
          #todo inject current resilienct test name in messages
          Log.info { "Heartbeat not found" }
          heartbeat_found = false
      end

    else
      heartbeat_found = false
      puts "no 5g labels".colorize(:red)
    end

    #todo move this to validator code code
    if heartbeat_found 
      resp = upsert_passed_task(testsuite_task,"✔️  PASSED: Chaos service degradation is less than 50%.", task_start_time)
    else
      resp = upsert_failed_task(testsuite_task, "✖️  FAILED: Chaos service degradation is more than 50%.", task_start_time)
    end
    resp
  end
end
