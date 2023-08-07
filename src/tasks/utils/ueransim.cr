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


end

