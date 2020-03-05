require "./spec_helper"
require "colorize"
require "../src/tasks/utils.cr"
require "file_utils"

describe "Utils" do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr helm_local_install`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr sample_coredns_cleanup`
    $?.success?.should be_true
  end
  it "'wait_for_install' should wait for a cnf to be installed" do
    current_dir = FileUtils.pwd 
    puts current_dir
    helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    puts helm
    helm_install = `#{helm} install coredns stable/coredns`
    puts helm_install
    wait_for_install("coredns-coredns")
    current_replicas = `kubectl get deployments coredns-coredns -o=jsonpath='{.status.readyReplicas}'`
    (current_replicas.to_i > 0).should be_true
  end
end
