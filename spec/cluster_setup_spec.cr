require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "kubectl_client"
require "cluster_tools"

describe "Cluster Setup" do

  before_each do
    `./cnf-testsuite cleanup`
    $?.success?.should be_true
  end

  it "'install_cluster_tools' should give a message if namespace does not exist", tags: ["cluster_setup"]  do
    KubectlClient::Delete.command("namespace #{ClusterTools.namespace}")
    response_s = `./cnf-testsuite install_cluster_tools`
    LOGGING.info response_s
    $?.success?.should be_false
    (/please run cnf-testsuite setup/ =~ response_s).should_not be_nil
  end
  
  it "'install_cluster_tools' should give a message if namespace does not exist even after setup", tags: ["cluster_setup"]  do
    `./cnf-testsuite setup`

    KubectlClient::Delete.command("namespace #{ClusterTools.namespace}")

    response_s = `./cnf-testsuite install_cluster_tools`
    LOGGING.info response_s
    $?.success?.should be_false
    (/please run cnf-testsuite setup/ =~ response_s).should_not be_nil
  end

  it "'uninstall_cluster_tools' should give a message if namespace does not exist", tags: ["cluster_setup"]  do
    response_s = `./cnf-testsuite uninstall_cluster_tools`
    LOGGING.info response_s
    $?.success?.should be_false
    (/please run cnf-testsuite setup/ =~ response_s).should_not be_nil
  end

end
