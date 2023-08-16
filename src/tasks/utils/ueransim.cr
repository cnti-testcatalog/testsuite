require "cluster_tools"
module UERANSIM 
  # MYSQL_PORT = "3306" 
  # def self.match()
  #   ClusterTools.local_match_by_image_name(["mysql/mysql-server","bitnami/mysql"])
  #   # ClusterTools.local_match_by_image_name("bitnami/mysql")
  # end
  def self.uninstall
    Log.for("verbose").info { "uninstall_ueransim" } 
    Helm.delete("ueransim")
  end

  # todo make this work without having the test-suite src
  def self.install
    Log.info {"Installing mysql-operator "}
    Helm.install("ueransim")
    KubectlClient::Get.resource_wait_for_install("Pod", "ueransim")
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

