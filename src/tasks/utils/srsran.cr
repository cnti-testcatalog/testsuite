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
    core = config.common.five_g_parameters.amf_label 
    Log.info { "core: #{core}" }
    #todo use sane defaults (i.e. search for amf, upf, etc in pod names) if no 5gcore labels are present
    amf_service_name = config.common.five_g_parameters.amf_service_name 
    mmc = config.common.five_g_parameters.mmc 
    mnc = config.common.five_g_parameters.mnc 
    sst = config.common.five_g_parameters.sst 
    sd = config.common.five_g_parameters.sd 
    tac = config.common.five_g_parameters.tac 
    enabled = config.common.five_g_parameters.enabled 
    count = config.common.five_g_parameters.count 
    initialMSISDN = config.common.five_g_parameters.initialMSISDN 
    key = config.common.five_g_parameters.key 
    op = config.common.five_g_parameters.op 
    opType = config.common.five_g_parameters.opType 
    type = config.common.five_g_parameters.type 
    apn = config.common.five_g_parameters.apn 
    emergency = config.common.five_g_parameters.emergency 

    if core 
      all_pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
      ueran_pods = KubectlClient::Get.pods_by_label(all_pods, "app.kubernetes.io/name", "ueransim-gnb")

      Log.info { "ueran_pods: #{ueran_pods}" }
      unless ueran_pods[0]? == nil
        Log.info { "Found ueransim ... deleting" }
        Helm.delete("ueransim -n testsuite-5g")
      end
      Helm.helm_repo_add("openverso","https://gradiant.github.io/openverso-charts/")
      Helm.fetch("openverso/ueransim-gnb --version 0.2.5 --untar")

      protectionScheme = config.common.five_g_parameters.protectionScheme
      unless protectionScheme.nil? || protectionScheme.empty?
        protectionScheme = "protectionScheme: #{protectionScheme}"
      end
      publicKey = config.common.five_g_parameters.publicKey
      unless publicKey.nil? || publicKey.empty?
        publicKey = "publicKey: '#{publicKey}'"
      end
      publicKeyId = config.common.five_g_parameters.publicKeyId 
      unless publicKeyId.nil? || publicKeyId.empty?
        publicKeyId = "publicKeyId: #{publicKeyId}"
      end
      routingIndicator = config.common.five_g_parameters.routingIndicator
      unless routingIndicator.nil? || routingIndicator.empty?
        routingIndicator = "routingIndicator: '#{routingIndicator}'"
      end

      ue_values = UERANSIM::Template.new(amf_service_name,
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
      Helm.install("-n testsuite-5g ueransim #{Dir.current}/ueransim-gnb --values ./gnb-ues-values.yaml")
      Log.info { "after helm install" }
      KubectlClient::Get.resource_wait_for_install("Pod", "ueransim", namespace: "testsuite-5g")
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
    def initialize(@amf_service_name : String,
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

