require "cluster_tools"
require "./k8s_tshark.cr"
module ORANMonitor 

  def self.isCNFaRIC?(cnf_config)
    ric = cnf_config[:ric_label]? 
    Log.info { "ric: #{ric}" }
    ric_key : String  = ""
    ric_value : String = ""
    ric_key = cnf_config[:ric_label].split("=").first if ric
    ric_value = cnf_config[:ric_label].split("=").last if ric
    if ric && !ric.empty?
      Log.info { "cnf is a ric: #{ric}" }
      ret = {:ric_key => ric_key, :ric_value => ric_value}
    else
      Log.info { "cnf not a ric: #{ric}" }
     ret = nil
    end 
    ret
  end
  
  def self.start_e2_capture?(cnf_config)
    ric_key : String  = ""
    ric_value : String = ""
    tshark_log_name : String | Nil
    ric = isCNFaRIC?(cnf_config)
    if ric
      ric_key = ric[:ric_key]
      ric_value = ric[:ric_value]
      command = "-i any -f 'sctp port 36421' -d 'sctp.port==36421,e2ap' -T json"
      # tshark_log_name = K8sTshark.log_of_tshark_by_label(command, ric_key, core_value)
      #todo check all nodes?
      nodes = KubectlClient::Get.schedulable_nodes_list
      node = nodes.first
      tshark_log_name = K8sTshark.log_of_tshark_by_node(command,node)
    else
      tshark_log_name = nil
    end
    tshark_log_name
  end

  def self.e2_session_established?(tshark_log_name)
    Log.info { "e2_session_established tshark_log_name: #{tshark_log_name}" }
    e2_found : Bool = false
    if tshark_log_name && 
        !tshark_log_name.empty? && 
        (tshark_log_name =~ /not found/) == nil

      if K8sTshark.regex_tshark_log(/e2ap\.successfulOutcome_element[^$]*e2ap.ric_ID/, tshark_log_name) 
        Log.info { "regex found " }
        e2_found = true
      else
        Log.info { "regex not found " }
        e2_found = false
      end
      Log.info { "found e2ap.successfulOutcome_element followed by e2ap.ric_ID?: #{e2_found}" }

      #todo delete log file
    else
      e2_found = false
      puts "no e2 log".colorize(:red)
    end
    e2_found
  end

end

