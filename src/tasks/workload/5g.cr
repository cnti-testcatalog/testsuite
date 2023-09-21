# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "Test if a 5G core supports SUCI Concealment"
task "suci_enabled" do |_, args|
  CNFManager::Task.task_runner(args) do |args, config|
    Log.info { "Running suci_enabled test" }
    Log.debug { "cnf_config: #{config}" }
    suci_found : Bool | Nil
    core = config.cnf_config[:core_label]? 
    Log.info { "core: #{core}" }
    core_key : String  = ""
    core_value : String = ""
    core_key = config.cnf_config[:core_label].split("=").first if core
    core_value = config.cnf_config[:core_label].split("=").last if core
    if core 

      command = "-ni any -Y nas_5gs.mm.type_id -T json"
      tshark_log_name = K8sTshark.log_of_tshark_by_label(command, core_key, core_value)
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
      resp = upsert_passed_task("suci_enabled","✔️  PASSED: Core uses SUCI 5g authentication" )
    else
      resp = upsert_failed_task("suci_enabled", "✖️  FAILED: Core does not use SUCI 5g authentication")
    end
    resp
  ensure
    Helm.delete("ueransim")
    ClusterTools.uninstall
    ClusterTools.install
  end

end
