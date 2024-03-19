# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "The CNF test suite checks to see if 5g CNFs follow cloud native principles"
task "5g", ["smf_upf_core_validator", "suci_enabled"] do |_, args|
  stdout_score("5g")
  case "#{ARGV.join(" ")}" 
  when /5g/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end

desc "Test if a 5G core is valid"
task "smf_upf_core_validator" do |t, args|
  #todo change to 5g_core_validator
  CNFManager::Task.task_runner(args, task: t) do |args, config|

		# todo add other resilience and compatiblity tests

    args.named["reslience_tests"]="pod_network_latency, pod_delete"

		# todo find heartbeat for ran
    t.invoke("smf_upf_heartbeat", args)
  end
end

desc "Test if a 5G core has SMF/UPF heartbeat"
task "smf_upf_heartbeat" do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    Log.for(t.name).info { "named args: #{args.named}" }
    baseline_count : Int32 | Float64 | String | Nil
    if args.named["baseline_count"]?
      baseline_count = args.named["baseline_count"].to_i
    else
      baseline_count = nil
    end

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
        tshark_log_name = K8sTshark.log_of_tshark_by_label(command, smf_key, smf_value, duration: "120")
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


      tshark_log_name = K8sTshark.log_of_tshark_by_label(command, smf_key, smf_value, duration: "120")
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
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "Chaos service degradation is less than 50%")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Chaos service degradation is more than 50%")
    end
  end
end

#todo move to 5g test files
desc "Test if a 5G core supports SUCI Concealment"
task "suci_enabled" do |t, args|
  CNFManager::Task.task_runner(args, task: t) do |args, config|
    suci_found : Bool | Nil
    core = config.cnf_config[:amf_label]? 
    Log.info { "core: #{core}" }
    core_key : String  = ""
    core_value : String = ""
    core_key = config.cnf_config[:amf_label].split("=").first if core
    core_value = config.cnf_config[:amf_label].split("=").last if core
    if core 

      command = "-ni any -Y nas_5gs.mm.type_id -T json"
      tshark_log_name = K8sTshark.log_of_tshark_by_label_bg(command, core_key, core_value)
      if tshark_log_name && 
          !tshark_log_name.empty? && 
          (tshark_log_name =~ /not found/) == nil

        #todo put in prereq
        UERANSIM.install(config)
        sleep 30.0
        #TODO 5g RAN (only) mobile traffic check ????
        # use suci encyption but don't use a null encryption key
        if K8sTshark.regex_tshark_log(/"nas_5gs.mm.type_id": "1"/, tshark_log_name) &&

            !K8sTshark.regex_tshark_log(/"nas_5gs.mm.suci.scheme_id": "0"/, tshark_log_name) &&
            !K8sTshark.regex_tshark_log(/"nas_5gs.mm.suci.pki": "0"/, tshark_log_name) 
          suci_found = true
        else
          suci_found = false
        end
        Log.info { "found nas_5gs.mm.type_id: 1: #{suci_found}" }

        #todo delete log file
      else
        suci_found = false
        puts "no 5g labels".colorize(:red)
      end
    else
      suci_found = false
      puts "You must set the core label for you AMF node".colorize(:red)
    end


    if suci_found
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Passed, "Core uses SUCI 5g authentication")
    else
      CNFManager::TestcaseResult.new(CNFManager::ResultStatus::Failed, "Core does not use SUCI 5g authentication")
    end
  ensure
    Helm.delete("ueransim")
    ClusterTools.uninstall
    ClusterTools.install
  end

end

