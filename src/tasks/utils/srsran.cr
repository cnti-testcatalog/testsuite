require "cluster_tools"
module SRSRAN 
  # MYSQL_PORT = "3306" 
  # def self.match()
  #   ClusterTools.local_match_by_image_name(["mysql/mysql-server","bitnami/mysql"])
  #   # ClusterTools.local_match_by_image_name("bitnami/mysql")
  # end

  def self.uninstall
    Log.for("verbose").info { "uninstall_srsran" } 
    Helm.delete("srsran")
  end


  def self.install(config)
    Log.info {"Installing srsran"}
    core = config.cnf_config[:core_label]? 
    Log.info { "core: #{core}" }
    #todo use sane defaults (i.e. search for amf, upf, etc in pod names) if no 5gcore labels are present
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
    core_key : String  = ""
    core_value : String = ""
    core_key = config.cnf_config[:core_label].split("=").first if core
    core_value = config.cnf_config[:core_label].split("=").last if core
    if core 
      all_pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
      ueran_pods = KubectlClient::Get.pods_by_label(all_pods, "app.kubernetes.io/name", "ueransim-gnb")

      Log.info { "ueran_pods: #{ueran_pods}" }
      unless ueran_pods[0]? == nil
        Log.info { "Found ueransim ... deleting" }
        Helm.delete("ueransim")
      end
      Helm.helm_repo_add("openverso","https://gradiant.github.io/openverso-charts/")
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
      KubectlClient::Get.resource_wait_for_install("Pod", "ueransim")
      true
    else
      false
      puts "You must set the core label for your AMF node".colorize(:red)
    end
  end

  class Template 
    # The argument for insecure_registries is a string
    # because the template only writes the content
    # and expects a list of comma separated strings.
    def initialize(@amf_pod_name : String,
                   @mmc : String,
                   @mnc : String,
                   @sst : String,
                   @sd : String,
                   @tac : String,
                   @protectionScheme : String,
                   @publicKey : String,
                   @publicKeyId : String,
                   @routingIndicator : String,
                   @enabled : String,
                   @count : String,
                   @initialMSISDN : String,
                   @key : String,
                   @op : String,
                   @opType : String,
                   @type : String,
                   @apn : String,
                   @emergency : String
                  )
    end
    ECR.def_to_s("src/templates/ues-values-template.yml.ecr")
  end


end

