require "./spec_helper"
require "colorize"
require "../src/tasks/utils.cr"
require "file_utils"
require "sam"

describe "Utils" do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr helm_local_install`
    $?.success?.should be_true
  end

  after_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr sample_coredns_setup`
    $?.success?.should be_true
  end

  before_each do
    `crystal src/cnf-conformance.cr cleanup`
    $?.success?.should be_true
  end

  after_each do
    `crystal src/cnf-conformance.cr cleanup`
    $?.success?.should be_true
  end
  
  it "'wait_for_install' should wait for a cnf to be installed" do
    `crystal src/cnf-conformance.cr sample_coredns_setup`
    $?.success?.should be_true

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

  it "'sample_setup' should set up a sample cnf" do
    args = Sam::Args.new
    sample_setup(sample_dir: "sample-cnfs/sample-coredns-cnf", release_name: "coredns", deployment_name: "coredns-coredns", helm_chart: "stable/coredns", helm_directory: "cnfs/coredns/helm_chart/coredns", git_clone_url: "https://github.com/coredns/coredns.git" )
    # check if directory exists
    (Dir.exists? "sample-cnfs/sample-coredns-cnf").should be_true
    (File.exists?("cnfs/coredns/cnf-conformance.yml")).should be_true
    (File.exists?("cnfs/coredns/cnf-conformance.yml")).should be_true
    (File.exists?("cnfs/coredns/helm_chart/coredns/Chart.yaml")).should be_true
  end

  it "'sample_setup_args' should set up a sample cnf from a argument", tags: "WIP" do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-coredns-cnf", args: args, verbose: true )
    # check if directory exists
    (Dir.exists? "sample-cnfs/sample-coredns-cnf").should be_true
    (File.exists?("cnfs/coredns/cnf-conformance.yml")).should be_true
    (File.exists?("cnfs/coredns/cnf-conformance.yml")).should be_true
    (File.exists?("cnfs/coredns/helm_chart/coredns/Chart.yaml")).should be_true
  end

  it "'sample_cleanup' should clean up a sample cnf from a argument", tags: "WIP" do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-coredns-cnf", args: args, verbose: true )
    sample_cleanup(sample_dir: "sample-cnfs/sample-coredns-cnf", verbose: true)
    # check if directory exists
    (Dir.exists? "cnfs/coredns").should be_false
    (File.exists?("cnfs/coredns/cnf-conformance.yml")).should be_false
    (File.exists?("cnfs/coredns/cnf-conformance.yml")).should be_false
    (File.exists?("cnfs/coredns/helm_chart/coredns/Chart.yaml")).should be_false
  end
end
