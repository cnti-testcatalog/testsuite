require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "file_utils"
require "sam"

describe "SampleUtils" do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `./cnf-conformance helm_local_install`
    $?.success?.should be_true
    `./cnf-conformance cleanup`
    $?.success?.should be_true
  end

   after_all do
     # puts `pwd` 
     # puts `echo $KUBECONFIG`
     `./cnf-conformance sample_coredns_setup`
     $?.success?.should be_true
   end

  after_each do
    `./cnf-conformance cleanup`
    $?.success?.should be_true
  end

  it "'wait_for_install' should wait for a cnf to be installed", tags: "happy-path"  do
    `./cnf-conformance sample_coredns_setup`
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

  it "'sample_setup' should set up a sample cnf", tags: "happy-path"  do
    args = Sam::Args.new
    sample_setup(config_file: "sample-cnfs/sample-generic-cnf", release_name: "coredns", deployment_name: "coredns-coredns", helm_chart: "stable/coredns", helm_directory: "helm_chart", git_clone_url: "https://github.com/coredns/coredns.git", wait_count: 0 )
    # check if directory exists
    (Dir.exists? "cnfs/coredns-coredns").should be_true
    (File.exists?("cnfs/coredns-coredns/cnf-conformance.yml")).should be_true
    (File.exists?("cnfs/coredns-coredns/helm_chart/Chart.yaml")).should be_true
    sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (Dir.exists? "cnfs/coredns-coredns").should be_false
  end

  it "'sample_setup_args' should set up a sample cnf from a argument", tags: "happy-path"  do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 0 )
    # check if directory exists
    (Dir.exists? "cnfs/coredns-coredns").should be_true
    (File.exists?("cnfs/coredns-coredns/cnf-conformance.yml")).should be_true
    (File.exists?("cnfs/coredns-coredns/helm_chart/Chart.yaml")).should be_true
    sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (Dir.exists? "cnfs/coredns-coredns").should be_false
  end

  it "'sample_setup_args' should set up a sample cnf from a config file", tags: "happy-path"  do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf/cnf-conformance.yml", args: args, verbose: true, wait_count: 0 )
    # check if directory exists
    (Dir.exists? "sample-cnfs/sample-generic-cnf").should be_true
    (File.exists?("cnfs/coredns-coredns/cnf-conformance.yml")).should be_true
    (File.exists?("cnfs/coredns-coredns/helm_chart/Chart.yaml")).should be_true
    sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (Dir.exists? "cnfs/coredns-coredns").should be_false
  end

  it "'sample_cleanup' should clean up a sample cnf from a argument", tags: "happy-path"  do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 0 )
    cleanup = sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (cleanup).should be_true 
    (Dir.exists? "cnfs/coredns-coredns").should be_false
    (File.exists?("cnfs/coredns-coredns/cnf-conformance.yml")).should be_false
    (File.exists?("cnfs/coredns-coredns/helm_chart/Chart.yaml")).should be_false
  end

  it "'sample_setup_args' should be able to deploy using a helm_directory", tags: "happy-path"  do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
    (Dir.exists? "cnfs/privileged-coredns-coredns").should be_true
    # should not clone
    (Dir.exists? "cnfs/privileged-coredns-coredns/privileged-coredns").should be_false
    (File.exists? "cnfs/privileged-coredns-coredns/cnf-conformance.yml").should be_true
    (File.exists? "cnfs/privileged-coredns-coredns/chart/Chart.yaml").should be_true
    sample_cleanup(config_file: "sample-cnfs/sample_privileged_cnf", verbose: true)
    (Dir.exists? "cnfs/privileged-coredns-coredns").should be_false
  end

  it "'cnf_conformance_dir' should return the short name of the destination cnf directory", tags: ["WIP", "happy-path"]  do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 0 )
    (cnf_conformance_dir).should eq("coredns-coredns")
  end

  it "'sample_destination_dir' should return the full path of the potential destination cnf directory based on the source sample cnf directory", tags: "WIP" do
    args = Sam::Args.new
    sample_destination_dir("sample-generic-cnf").should contain("/cnfs/sample-generic-cnf")
  end

  it "'cnf_destination_dir' should return the full path of the potential destination cnf directory based on the deployment name", tags: "WIP" do
    args = Sam::Args.new
    cnf_destination_dir("spec/fixtures/cnf-conformance.yml").should contain("/cnfs/coredns-coredns")
  end

  it "'cnf_conformance_yml(sample_cnf_destination_dir)' should return the yaml for the passed cnf directory", tags: "happy-path"  do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 1 )
    sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", args: args, verbose: true )
    yml = cnf_conformance_yml("privileged-coredns-coredns")
    ("#{yml.get("release_name").as_s?}").should eq("privileged-coredns")
    yml = cnf_conformance_yml("cnfs/privileged-coredns-coredns")
    ("#{yml.get("release_name").as_s?}").should eq("privileged-coredns")
  end

  it "'cnf_conformance_dir(source_short_dir)' should use full cnfs path for passed source cnf", tags: "happy-path"  do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 1 )
    sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", args: args, verbose: true )
    #TODO this will no longer work since we are specifiying yml path
    # cnf_conformance_dir("sample_privileged_cnf").should contain("privileged-coredns")
    cnf_conformance_dir("sample-cnfs/sample_privileged_cnf").should contain("privileged-coredns")
  end

  it "'helm_repo_add' should add a helm repo if the helm repo is valid", tags: "happy-path"  do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 1 )
    helm_repo_add.should eq(true)
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-conformance.yml"])
    helm_repo_add(args: args).should eq(true)
  end

  it "'get_parsed_cnf_conformance_yml' should return the cnf config file based on a yml", tags: "happy-path"  do
    args = Sam::Args.new(["yml-file=./sample-cnfs/sample-generic-cnf/cnf-conformance.yml"])
    yml = get_parsed_cnf_conformance_yml(args)
    ("#{yml.get("release_name").as_s?}").should eq("coredns")
  end

  it "'helm_repo_add' should return false if the helm repo is invalid", tags: "happy-path"  do
    helm_repo_add("invalid", "invalid").should eq(false)
  end
end
