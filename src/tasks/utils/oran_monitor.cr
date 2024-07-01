require "cluster_tools"
require "./k8s_tshark.cr"
module ORANMonitor 

  def self.isCNFaRIC?(cnf_config)
    Log.info { "isCNFaRIC?" }
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
    Log.info { "start_e2_capture" }
    ric_key : String  = ""
    ric_value : String = ""
    capture : K8sTshark::TsharkPacketCapture | Nil
    ric = isCNFaRIC?(cnf_config)
    if ric
      ric_key = ric[:ric_key]
      ric_value = ric[:ric_value]
      command = "-i any -f 'sctp port 36421' -d 'sctp.port==36421,e2ap' -T json"
      #todo check all nodes?
      nodes = KubectlClient::Get.schedulable_nodes_list
      node = nodes.first

      resp = ClusterTools.exec_by_node("tshark --version", node)
      Log.info { "tshark must be version 4.0.3 or higher" }
      Log.info { "tshark output #{resp[:output]}" }

      capture = K8sTshark::TsharkPacketCapture.new
      capture.begin_capture_by_node(node, command)
    else
      capture = nil
    end
  
    capture
  end

  def self.e2_session_established?(capture : K8sTshark::TsharkPacketCapture | Nil)
    Log.info { "e2_session_established" }
    e2_found : Bool = false
    
    if !capture.nil?
      if capture.regex_match?(/e2ap\.successfulOutcome_element[^$]*e2ap.ric_ID/) 
        Log.info { "regex found " }
        e2_found = true
      else
        Log.info { "regex not found " }
      end

      Log.info { "found e2ap.successfulOutcome_element followed by e2ap.ric_ID?: #{e2_found}" }

      capture.terminate_capture
    end

    e2_found
  end
end
