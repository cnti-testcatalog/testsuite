require "cluster_tools"
module Mysql
  MYSQL_PORT = "3306" 
  MYSQL_IMAGES = ["mysql/mysql-server","bitnami/mysql"]
  def self.match()
    ClusterTools.local_match_by_image_name(MYSQL_IMAGES)
    # ClusterTools.local_match_by_image_name("bitnami/mysql")
  end
  def self.uninstall
    Log.debug { "uninstall_mysql" } 
    KubectlClient::Delete.file("https://raw.githubusercontent.com/mysql/mysql-operator/trunk/samples/sample-cluster.yaml --wait=false")
    Helm.uninstall("mysql-operator", "mysql-operator")
  end

  # todo make this work without having the test-suite src
  def self.install
    Log.info {"Installing mysql-operator "}
    Helm.install("mysql-operator", "sample-cnfs/mysql/mysql-operator/helm/mysql-operator", namespace: mysql-operator, create_namespace: true)
    temp_pw = Random.rand.to_s
    KubectlClient::Create.command(%(secret generic mypwds --from-literal=rootUser=root --from-literal=rootHost=% --from-literal=rootPassword="#{temp_pw}"))
    KubectlClient::Apply.file("https://raw.githubusercontent.com/mysql/mysql-operator/trunk/samples/sample-cluster.yaml")
    KubectlClient::Get.resource_wait_for_install("Pod", "mycluster-2")
    # KubectlClient::Get.resource_wait_for_install("Pod", "jaeger-hotrod")
    # KubectlClient::Get.resource_wait_for_install("Deployment", "jaeger-query")
    # KubectlClient::Get.resource_wait_for_install("Daemonset", "jaeger-agent")
    temp_pw
  end


end

