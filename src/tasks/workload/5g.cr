# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "Test if a 5G core supports SUCI Concealment"
task "suci_enabled" do |_, args|
  test_name = "specialized_init_system"
  CNFManager::Task.task_runner(args) do |args, config|
    Log.info { "Running #{test_name} test" }
    Log.debug { "cnf_config: #{config}" }
    core = config.cnf_config[:core_label]? 
    amf_pod_name = config.cnf_config[:fiveG_core][:amf_pod_name]? 
    mmc = config.cnf_config[:fiveG_core][:mmc]? 
    mnc = config.cnf_config[:fiveG_core][:mnc]? 
    sst = config.cnf_config[:fiveG_core][:sst]? 
    sd = config.cnf_config[:fiveG_core][:sd]? 
    tac = config.cnf_config[:fiveG_core][:tac]? 
    enabled = config.cnf_config[:fiveG_core][:enabled]? 
    count = config.cnf_config[:fiveG_core][:count]? 
    initialMSISDN = config.cnf_config[:fiveG_core][:initialMSISDN]? 
    key = config.cnf_config[:fiveG_core][:key]? 
    op = config.cnf_config[:fiveG_core][:op]? 
    opType = config.cnf_config[:fiveG_core][:opType]? 
    type = config.cnf_config[:fiveG_core][:type]? 
    apn = config.cnf_config[:fiveG_core][:apn]? 
    emergency = config.cnf_config[:fiveG_core][:emergency]? 
    suci_found : Bool | Nil
    Log.info { "core: #{core}" }
    core_key : String  = ""
    core_value : String = ""
    core_key = config.cnf_config[:core_label].split("=").first if core
    core_value = config.cnf_config[:core_label].split("=").last if core
    if core 



      #TODO cluster_tools exec tshark command: tshark -ni any -Y nas_5gs.mm.type_id -T json > test.file
      #todo use sane defaults (i.e. search for amf, upf, etc in pod names) if no 5gcore labels are present
      #todo get 5gcore pods
      all_pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
      # pods = KubectlClient::Get.pods_by_label(all_pods, "app.kubernetes.io/instance", "open5gs")
      pods = KubectlClient::Get.pods_by_label(all_pods, core_key, core_value)
      fivegpod = pods[0]?
        Log.info { "fivegpod: #{fivegpod}" }
      if fivegpod && fivegpod.dig?("metadata", "name")
        Log.info { "fivegpod #{fivegpod} metadata name: #{fivegpod.dig?("metadata", "name")}" }
        fivegcore_pod_name = fivegpod.dig("metadata", "name")
        Log.info { "fivegcore_pod_name: #{fivegcore_pod_name}" }
        # nodes = KubectlClient::Get.nodes_by_pod(fivegcore_pod_name)
        nodes = KubectlClient::Get.nodes_by_pod(fivegpod)
        node = nodes.first
        #todo get node for 5gcore
        #todo deploy ueransim to same node as the 5gcore
        #TODO look for connection text (sanity check)
        # ClusterTools.exec("tshark -ni any -Y nas_5gs.mm.type_id  -T json > test.log")
        #todo name_id = random number
        rnd = Random.new
        name_id = rnd.next_int
        tshark_log_name = "/tmp/tshark-#{name_id}.json"
        Log.info { "tshark_log_name #{tshark_log_name}" }
        ClusterTools.exec_by_node_bg("tshark -ni any -a duration:120 -Y nas_5gs.mm.type_id  -T json 2>&1 | tee #{tshark_log_name}", node)
        Log.info { "after exec by node bg" }

        #todo put in prereq

        ueran_pods = KubectlClient::Get.pods_by_label(all_pods, "app.kubernetes.io/name", "ueransim-gnb")

        Log.info { "ueran_pods: #{ueran_pods}" }
        unless ueran_pods[0]? == nil
          Log.info { "Found ueransim ... deleting" }
          Helm.delete("ueransim")
        end
        Helm.fetch("openverso/ueransim-gnb --version 0.2.5 --untar")

        protectionScheme = config.cnf_config[:fiveG_core][:protectionScheme]
        unless protectionScheme.empty?
          protectionScheme = "protectionScheme: #{config.cnf_config[:fiveG_core][:protectionScheme]}"
        end
        publicKey = config.cnf_config[:fiveG_core][:publicKey] 
          unless publicKey.empty?
            publicKey = "publicKey: '#{config.cnf_config[:fiveG_core][:publicKey]}'"
        end
        publicKeyId = config.cnf_config[:fiveG_core][:publicKeyId] 
          unless publicKeyId.empty?
            publicKeyId = "publicKeyId: #{config.cnf_config[:fiveG_core][:publicKeyId]}"
        end
        routingIndicator = config.cnf_config[:fiveG_core][:routingIndicator] 
          unless routingIndicator.empty?
            routingIndicator = "routingIndicator: '#{config.cnf_config[:fiveG_core][:routingIndicator]}'"
        end

        ue_values = UERANSIM::Template.new(amf_pod_name,
                                           mmc,
                                           mnc,
                                           sst,
                                           sd,
                                           tac,
                                           protectionScheme,
                                           publicKey,
                                           publicKeyId,
                                           routingIndicator,
                                           enabled,
                                           count,
                                           initialMSISDN,
                                           key,
                                           op,
                                           opType,
                                           type,
                                           apn,
                                           emergency 
                                          ).to_s
        Log.info { "ue_values: #{ue_values}" }
        File.write("gnb-ues-values.yaml", ue_values)
        # File.write("gnb-ues-values.yaml", UES_VALUES)
        File.write("#{Dir.current}/ueransim-gnb/resources/ue.yaml", UERANSIM_HELMCONFIG)
        Helm.install("ueransim #{Dir.current}/ueransim-gnb --values ./gnb-ues-values.yaml")
        Log.info { "after helm install" }

        # pid_log_names << pid_log_name


        # todo save off all directory/filenames into a hash
        #strace: Process 94273 attached
        # ---SIGURG {si_signo=SIGURG, si_code=SI_TKILL, si_pid=1, si_uid=0} ---
        # --- SIGTERM {si_signo=SIGTERM, si_code=SI_USER, si_pid=0, si_uid=0} ---
        #todo 2.2 wait for 30 seconds

        # ClusterTools.exec_by_node("bash -c 'sleep 10 && kill #{pid} && sleep 5 && kill -9 #{pid}'", node)
        sleep 30.0
        Log.info { "tshark_log_name: #{tshark_log_name}" }
        resp = File.read("#{tshark_log_name}")
        Log.info { "tshark_log_name resp: #{resp}" }
        if resp
          Log.info { "resp: #{resp}" }
          # use suci encyption but don't use a null encryption key
          if resp =~ /"nas_5gs.mm.type_id": "1"/ &&
              (resp =~ /"nas_5gs.mm.suci.scheme_id": "0"/) == nil &&
              (resp =~ /"nas_5gs.mm.suci.pki": "0"/) == nil
            suci_found = true
          else
            Log.info { "resp: #{resp}" }
            suci_found = false
          end
        else
          Log.info { "no response found for tshark_log_name" }
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

    #TODO tshark library
    #TODO 5g tools library
    #TODO 5g RAN and Core mobile traffic check (connection check)
    #TODO 5g RAN (only) mobile traffic check ????

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
