require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/mysql.cr"
require "kubectl_client"
require "../../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "State" do
  before_all do
    `./cnf-testsuite configuration_file_setup`
  end
  
  it "'elastic_volume' should pass if the cnf uses an elastic volume", tags: ["elastic_volume"]  do
    begin
      LOGGING.info `./cnf-testsuite -l info cnf_setup cnf-config=./sample-cnfs/sample-elastic-volume/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite -l info elastic_volumes verbose`
      LOGGING.info "Status:  #{response_s}"
      (/PASSED: Elastic Volumes Used/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-elastic-volume/cnf-testsuite.yml`
      $?.success?.should be_true
    end
  end

  it "'elastic_volume' should be skipped if the cnf does not use any volumes", tags: ["elastic_volume"]  do
    begin
      LOGGING.info `./cnf-testsuite -l info cnf_setup cnf-config=./sample-cnfs/sample_nonroot`
      $?.success?.should be_true
      response_s = `./cnf-testsuite -l info elastic_volumes verbose`
      LOGGING.info "Status:  #{response_s}"
      (/SKIPPED: No volumes used/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_nonroot`
      $?.success?.should be_true
    end
  end

  it "'database_persistence' should pass if the cnf uses a database that uses an elastic volume with a stateful set", tags: ["elastic_volume"]  do
    begin
      Log.info {"Installing Mysql "}
      # Mysql.install
      # todo make helm directories work with parameters
      ShellCmd.run("./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-mysql/cnf-testsuite.yml", "sample_cnf_setup")
      KubectlClient::Get.resource_wait_for_install("Pod", "mysql-0")
      # KubectlClient::Delete.file("https://raw.githubusercontent.com/mysql/mysql-operator/trunk/samples/sample-cluster.yaml  --wait=false")
      # temp_pw = Random.rand.to_s
      # KubectlClient::Create.command(%(secret generic mypwds --from-literal=rootUser=root --from-literal=rootHost=% --from-literal=rootPassword="#{temp_pw}"))
      # KubectlClient::Apply.file("https://raw.githubusercontent.com/mysql/mysql-operator/trunk/samples/sample-cluster.yaml")
      # KubectlClient::Get.resource_wait_for_install("Pod", "mycluster-2")
      response_s = `LOG_LEVEL=info ./cnf-testsuite database_persistence`
      Log.info {"Status:  #{response_s}"}
      (/PASSED: Elastic Volumes and Statefulsets Used/ =~ response_s).should_not be_nil
    ensure
      # Mysql.uninstall
       # KubectlClient::Delete.file("https://raw.githubusercontent.com/mysql/mysql-operator/trunk/samples/sample-cluster.yaml  --wait=false")
       # KubectlClient::Delete.file("https://raw.githubusercontent.com/mysql/mysql-operator/trunk/samples/sample-cluster.yaml")
      #todo fix cleanup for helm directory with parameters
      ShellCmd.run("./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-mysql/cnf-testsuite.yml", "sample_cnf_cleanup")
      ShellCmd.run("kubectl delete pvc data-mysql-0", "delete_pvc")
    end
  end

  it "'elastic_volume' should fail if the cnf doesn't use an elastic volume", tags: ["elastic_volume"]  do
    begin
      LOGGING.info `./cnf-testsuite -l info cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite -l info elastic_volumes verbose`
      LOGGING.info "Status:  #{response_s}"
      (/FAILED: Volumes used are not elastic volumes/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      $?.success?.should be_true
    end
  end

  it "'volume_hostpath_not_found' should pass if the cnf doesn't have a hostPath volume", tags: ["volume_hostpath_not_found"]  do
    begin
      `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite volume_hostpath_not_found verbose`
      LOGGING.info "Status:  #{response_s}"
      (/PASSED: hostPath volumes not found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      $?.success?.should be_true
    end
  end

  it "'volume_hostpath_not_found' should fail if the cnf has a hostPath volume", tags: ["volume_hostpath_not_found"]  do
    begin
      `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-fragile-state/cnf-testsuite.yml deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-testsuite volume_hostpath_not_found verbose`
      LOGGING.info "Status:  #{response_s}"
      (/FAILED: hostPath volumes found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-fragile-state/cnf-testsuite.yml deploy_with_chart=false`
      $?.success?.should be_true
    end
  end

  it "'no_local_volume_configuration' should fail if local storage configuration found", tags: ["no_local_volume_configuration"]  do
    begin
      # update the helm parameter with a schedulable node for the pv chart
      schedulable_nodes = KubectlClient::Get.schedulable_nodes
      update_yml("sample-cnfs/sample-local-storage/cnf-testsuite.yml", "release_name", "coredns --set worker_node='#{schedulable_nodes[0]}'")
      `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-local-storage/cnf-testsuite.yml verbose`
      $?.success?.should be_true
      response_s = `./cnf-testsuite no_local_volume_configuration verbose`
      LOGGING.info "Status:  #{response_s}"
      (/FAILED: local storage configuration volumes found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-local-storage/cnf-testsuite.yml deploy_with_chart=false`
      update_yml("sample-cnfs/sample-local-storage/cnf-testsuite.yml", "release_name", "coredns")
      $?.success?.should be_true
    end
  end

  it "'no_local_volume_configuration' should pass if local storage configuration is not found", tags: ["no_local_volume_configuration"]  do
    begin
      `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml verbose`
      $?.success?.should be_true
      response_s = `./cnf-testsuite no_local_volume_configuration verbose`
      LOGGING.info "Status:  #{response_s}"
      (/PASSED: local storage configuration volumes not found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml deploy_with_chart=false`
      $?.success?.should be_true
    end
  end
end
