require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "kubectl_client"
require "cluster_tools"

describe "Cluster Setup" do
  before_each do
    result = ShellCmd.run_testsuite("cleanup")
    result[:status].success?.should be_true
  end

  it "'install_cluster_tools' should give a message if namespace does not exist", tags: ["cluster_setup"]  do
    KubectlClient::Delete.command("namespace #{ClusterTools.namespace}")
    result = ShellCmd.run_testsuite("install_cluster_tools")
    result[:status].success?.should be_false
    (/Error: Namespace cnf-testsuite does not exist./ =~ result[:output]).should_not be_nil
  end
  
  it "'install_cluster_tools' should give a message if namespace does not exist even after setup", tags: ["cluster_setup"]  do
    result = ShellCmd.run_testsuite("setup")

    KubectlClient::Delete.command("namespace #{ClusterTools.namespace}")

    result = ShellCmd.run_testsuite("install_cluster_tools")
    result[:status].success?.should be_false
    (/Error: Namespace cnf-testsuite does not exist./ =~ result[:output]).should_not be_nil
  end

  it "'uninstall_cluster_tools' should give a message if namespace does not exist", tags: ["cluster_setup"]  do
    result = ShellCmd.run_testsuite("uninstall_cluster_tools")
    result[:status].success?.should be_false
    (/Error: Namespace cnf-testsuite does not exist./ =~ result[:output]).should_not be_nil
  end
end
