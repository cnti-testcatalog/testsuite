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

  it "'cnf_destination_dir' should return the full path of the potential destination cnf directory based on the deployment name", tags: "WIP" do
    args = Sam::Args.new
    cnf_destination_dir("spec/fixtures/cnf-conformance.yml").should contain("/cnfs/coredns-coredns")
  end

  it "'cnf_config_list' should return a list of all of the config files from the cnf directory", tags: "happy-path"  do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 1 )
    sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", args: args, verbose: true )
    cnf_config_list()[0].should contain("coredns-coredns/#{CONFIG_FILE}")
  end

  it "'helm_repo_add' should add a helm repo if the helm repo is valid", tags: "happy-path"  do
    args = Sam::Args.new
    sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 1 )
    # helm_repo_add.should eq(true)
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-conformance.yml"])
    helm_repo_add(args: args).should eq(true)
  end

  it "'helm_repo_add' should return false if the helm repo is invalid", tags: "happy-path"  do
    helm_repo_add("invalid", "invalid").should eq(false)
  end
end


it "'validate_cnf_conformance_yml' should warn when cnf config file yml has fields that are not a part of the validation type", tags: ["unhappy-path", "validate_config"]  do
  args = Sam::Args.new(["cnf-config=./spec/fixtures/cnf-conformance-unmapped-keys.yml"])

  yml = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
  puts yml.inspect
  ("#{yml.get("release_name").as_s?}").should eq("coredns")

  valid, warning_output = validate_cnf_conformance_yml(yml)

  (valid).should eq(true)
  (warning_output.size).should be > 1
end
