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


    #TODO cluster_tools exec tshark command: tshark -ni any -Y nas_5gs.mm.type_id -T json > test.file
    #todo use sane defaults (i.e. search for amf, upf, etc in pod names) if no 5gcore labels are present
    #todo get 5gcore pods
    all_pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(all_pods, "app.kubernetes.io/instance", "open5gs")
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
      ClusterTools.exec_by_node_bg("tshark -ni any -Y nas_5gs.mm.type_id  -T json 2>&1 | tee #{tshark_log_name}", node)
      Log.info { "after exec by node bg" }

      #todo put in prereq

      ueran_pods = KubectlClient::Get.pods_by_label(all_pods, "app.kubernetes.io/name", "ueransim-gnb")

      Log.info { "ueran_pods: #{ueran_pods}" }
      if ueran_pods[0]? == nil
           Helm.fetch("openverso/ueransim-gnb --version 0.2.5 --untar")
           File.write("gnb-ues-values.yaml", UES_VALUES)
           Helm.install("ueransim #{Dir.current}/ueransim-gnb --values ./gnb-ues-values.yaml")
           Log.info { "after helm install" }
         else
           Helm.delete("ueransim")
           Helm.fetch("openverso/ueransim-gnb --version 0.2.5 --untar")
           File.write("gnb-ues-values.yaml", UES_VALUES)
           Helm.install("ueransim #{Dir.current}/ueransim-gnb --values ./gnb-ues-values.yaml")
           Log.info { "after helm install" }
      end

      # pid_log_names << pid_log_name


      # todo save off all directory/filenames into a hash
      #strace: Process 94273 attached
      # ---SIGURG {si_signo=SIGURG, si_code=SI_TKILL, si_pid=1, si_uid=0} ---
      # --- SIGTERM {si_signo=SIGTERM, si_code=SI_USER, si_pid=0, si_uid=0} ---
      #todo 2.2 wait for 30 seconds

      # ClusterTools.exec_by_node("bash -c 'sleep 10 && kill #{pid} && sleep 5 && kill -9 #{pid}'", node)
      sleep 20.0
      Log.info { "tshark_log_name: #{tshark_log_name}" }
      resp = File.read("#{tshark_log_name}")
      Log.info { "tshark_log_name resp: #{resp}" }
      ans : Bool
      if resp
        Log.info { "resp: #{resp}" }
        if resp =~ /"nas_5gs.mm.type_id": "1"/
          ans = true
        else
          Log.info { "resp: #{resp}" }
          ans = false
        end
      else
        ans = false
      end
      Log.info { "found nas_5gs.mm.type_id: 1: #{ans}" }

      #todo delete log file
    else
      puts "no 5g labels"
    end

    #todo cluster_tools exec get text-<uniqueid>.file
    #TODO parse tshark command
    #TODO look for authentication text
    #todo cluster_tools exec delete text-<uniqueid>.file


    # extra
    #TODO tshark library
    #TODO 5g tools library
    #TODO 5g RAN and Core mobile traffic check (connection check)
    #TODO 5g RAN (only) mobile traffic check ????
    #TODO ueransim library (w/setup command)
    #TODO Open5gs libary (w/setup command)

    nil
  end

end
