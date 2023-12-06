require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"


module K8sTshark

  def self.log_of_tshark_by_label(command, label_key, label_value, duration="120") : String
      Log.info { "log_of_tshark_by_label command label_key label value: #{command} #{label_key} #{label_value}" }
      all_pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
      pods = KubectlClient::Get.pods_by_label(all_pods, label_key, label_value) 
      first_labeled_pod = pods[0]?
      Log.info { "first_labeled_pod: #{first_labeled_pod}" }
      if first_labeled_pod && first_labeled_pod.dig?("metadata", "name")
        Log.info { "first_labeled_pod #{first_labeled_pod} metadata name: #{first_labeled_pod.dig?("metadata", "name")}" }
        pod_name = first_labeled_pod.dig("metadata", "name")
        Log.info { "pod_name: #{pod_name}" }
        nodes = KubectlClient::Get.nodes_by_pod(first_labeled_pod)
        node = nodes.first
        #create a unique name for the log
        # rnd = Random.new
        # name_id = rnd.next_int
        # tshark_log_name = "/tmp/tshark-#{name_id}.json"
        # Log.info { "tshark_log_name #{tshark_log_name}" }
        #
        # #tshark -ni any  -Y nas_5gs.mm.type_id -T json 2>&1 | tee hi.log 
        # #command= -ni any  -Y nas_5gs.mm.type_id -T json
        # #todo check if tshark running already to keep from saturating network
        # #todo play with reducing default duration
        # ClusterTools.exec_by_node_bg("tshark #{command} -a duration:#{duration} 2>&1 | tee #{tshark_log_name}", node)
        # ClusterTools.exec_by_node_bg("tshark -ni any -a duration:120 -Y nas_5gs.mm.type_id  -T json 2>&1 | tee #{tshark_log_name}", node)
        # Log.info { "after exec by node bg" }
        # resp = tshark_log_name
        resp = log_of_tshark_by_node(command, node, duration)
      else
        resp = "label key:#{label_key} value: #{label_value} not found"
      end
      Log.info { "resp #{resp}" }
      resp
  end

  def self.log_of_tshark_by_label_bg(command, label_key, label_value, duration="120") : String
    Log.info { "log_of_tshark_by_label command label_key label value: #{command} #{label_key} #{label_value}" }
    all_pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(all_pods, label_key, label_value) 
    first_labeled_pod = pods[0]?
      Log.info { "first_labeled_pod: #{first_labeled_pod}" }
    if first_labeled_pod && first_labeled_pod.dig?("metadata", "name")
      Log.info { "first_labeled_pod #{first_labeled_pod} metadata name: #{first_labeled_pod.dig?("metadata", "name")}" }
      pod_name = first_labeled_pod.dig("metadata", "name")
      Log.info { "pod_name: #{pod_name}" }
      nodes = KubectlClient::Get.nodes_by_pod(first_labeled_pod)
      node = nodes.first
      #create a unique name for the log
      # rnd = Random.new
      # name_id = rnd.next_int
      # tshark_log_name = "/tmp/tshark-#{name_id}.json"
      # Log.info { "tshark_log_name #{tshark_log_name}" }
      #
      # #tshark -ni any  -Y nas_5gs.mm.type_id -T json 2>&1 | tee hi.log 
      # #command= -ni any  -Y nas_5gs.mm.type_id -T json
      # #todo check if tshark running already to keep from saturating network
      # #todo play with reducing default duration
      # ClusterTools.exec_by_node_bg("tshark #{command} -a duration:#{duration} 2>&1 | tee #{tshark_log_name}", node)
      # ClusterTools.exec_by_node_bg("tshark -ni any -a duration:120 -Y nas_5gs.mm.type_id  -T json 2>&1 | tee #{tshark_log_name}", node)
      # Log.info { "after exec by node bg" }
      # resp = tshark_log_name
      resp = log_of_tshark_by_node_bg(command, node, duration="120")
    else
      resp = "label key:#{label_key} value: #{label_value} not found"
    end
    Log.info { "resp #{resp}" }
    resp
  end


  def self.log_of_tshark_by_node(command, node, duration="120") : String
    Log.info { "log_of_tshark_by_node: command #{command}" }
    #create a unique name for the log
    rnd = Random.new
    name_id = rnd.next_int.abs
    tshark_log_name = "/tmp/tshark-#{name_id}.json"
    Log.info { "log_of_tshark_by_node tshark_log_name #{tshark_log_name}" }

    #tshark -ni any  -Y nas_5gs.mm.type_id -T json 2>&1 | tee hi.log 
    #command= -ni any  -Y nas_5gs.mm.type_id -T json
    #todo check if tshark running already to keep from saturating network
    ClusterTools.exec_by_node("tshark #{command} -a duration:#{duration} 2>&1 | tee #{tshark_log_name}", node)
    Log.info { "after exec by node bg" }
    tshark_log_name
  end

  def self.log_of_tshark_by_node_bg(command, node, duration="120") : String
    Log.info { "log_of_tshark_by_node: command #{command}" }
    #create a unique name for the log
    rnd = Random.new
    name_id = rnd.next_int.abs
    tshark_log_name = "/tmp/tshark-#{name_id}.json"
    Log.info { "log_of_tshark_by_node tshark_log_name #{tshark_log_name}" }

    #tshark -ni any  -Y nas_5gs.mm.type_id -T json 2>&1 | tee hi.log 
    #command= -ni any  -Y nas_5gs.mm.type_id -T json
    #todo check if tshark running already to keep from saturating network
    ClusterTools.exec_by_node_bg("tshark #{command} -a duration:#{duration} 2>&1 | tee #{tshark_log_name}", node)
    Log.info { "after exec by node bg" }
    tshark_log_name
  end


  def self.regex_tshark_log_scan(regex, tshark_log_name)
    Log.info { "regex_tshark_log regex tshark_log_name: #{regex} #{tshark_log_name}" }
    resp = File.read("#{tshark_log_name}")
    Log.debug { "tshark_log_name resp: #{resp}" }
    if resp
      Log.debug { "resp: #{resp}" }
      ret = resp.scan(regex) 
    else
      Log.info { "file empty" }
      ret = nil
    end
    Log.info { "#{regex}: #{ret}" }
    ret
  end

  def self.regex_tshark_log_match(regex, tshark_log_name)
    Log.info { "regex_tshark_log regex tshark_log_name: #{regex} #{tshark_log_name}" }
    resp = File.read("#{tshark_log_name}")
    Log.info { "tshark_log_name resp: #{resp}" }
    if resp
      Log.info { "resp: #{resp}" }
      ret = resp =~ regex 
    else
      Log.info { "file empty" }
      ret = nil
    end
    Log.info { "#{regex}: #{ret}" }
    ret
  end

  def self.regex_tshark_log(regex, tshark_log_name)
    Log.info { "regex_tshark_log regex tshark_log_name: #{regex} #{tshark_log_name}" }
    regex_found : Bool | Nil
    if regex_tshark_log_match(regex, tshark_log_name) 
      regex_found = true
    else
      regex_found = false
    end
    regex_found
  end

end
