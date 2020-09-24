require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "file_utils"
require "sam"

describe "SampleUtils" do
  before_all do
    # LOGGING.debug `pwd` 
    # LOGGING.debug `echo $KUBECONFIG`
    `./cnf-conformance helm_local_install`
    $?.success?.should be_true
    `./cnf-conformance cleanup`
    $?.success?.should be_true
  end

   after_all do
     # LOGGING.debug `pwd` 
     # LOGGING.debug `echo $KUBECONFIG`
     `./cnf-conformance sample_coredns_setup`
     $?.success?.should be_true
   end

  after_each do
    `./cnf-conformance cleanup`
    $?.success?.should be_true
  end

  it "'CNFManager.wait_for_install' should wait for a cnf to be installed", tags: "happy-path"  do
    `./cnf-conformance sample_coredns_setup`
    $?.success?.should be_true

    current_dir = FileUtils.pwd 
    LOGGING.info current_dir
    #helm = "#{current_dir}/#{TOOLS_DIR}/helm/linux-amd64/helm"
    helm = CNFSingleton.helm
    LOGGING.info helm
    helm_install = `#{helm} install coredns stable/coredns`
    LOGGING.info helm_install
    CNFManager.wait_for_install("coredns-coredns")
    current_replicas = `kubectl get deployments coredns-coredns -o=jsonpath='{.status.readyReplicas}'`
    (current_replicas.to_i > 0).should be_true
  end

  it "'CNFManager.sample_setup' should set up a sample cnf", tags: "happy-path"  do
    args = Sam::Args.new
    CNFManager.sample_setup(config_file: "sample-cnfs/sample-generic-cnf", release_name: "coredns", deployment_name: "coredns-coredns", helm_chart: "stable/coredns", helm_directory: "helm_chart", git_clone_url: "https://github.com/coredns/coredns.git", wait_count: 0 )
    # check if directory exists
    (Dir.exists? "cnfs/coredns-coredns").should be_true
    (File.exists?("cnfs/coredns-coredns/cnf-conformance.yml")).should be_true
    (File.exists?("cnfs/coredns-coredns/helm_chart/Chart.yaml")).should be_true
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (Dir.exists? "cnfs/coredns-coredns").should be_false
  end

  it "'CNFManager.sample_setup_args' should set up a sample cnf from a argument", tags: "happy-path"  do
    args = Sam::Args.new
    CNFManager.sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 0 )
    # check if directory exists
    (Dir.exists? "cnfs/coredns-coredns").should be_true
    (File.exists?("cnfs/coredns-coredns/cnf-conformance.yml")).should be_true
    (File.exists?("cnfs/coredns-coredns/helm_chart/Chart.yaml")).should be_true
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (Dir.exists? "cnfs/coredns-coredns").should be_false
  end

  it "'CNFManager.sample_setup_args' should set up a sample cnf from a config file", tags: "happy-path"  do
    args = Sam::Args.new
    CNFManager.sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf/cnf-conformance.yml", args: args, verbose: true, wait_count: 0 )
    # check if directory exists
    (Dir.exists? "sample-cnfs/sample-generic-cnf").should be_true
    (File.exists?("cnfs/coredns-coredns/cnf-conformance.yml")).should be_true
    (File.exists?("cnfs/coredns-coredns/helm_chart/Chart.yaml")).should be_true
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (Dir.exists? "cnfs/coredns-coredns").should be_false
  end

  it "'CNFManager.sample_cleanup' should clean up a sample cnf from a argument", tags: "happy-path"  do
    args = Sam::Args.new
    CNFManager.sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 0 )
    cleanup = CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (cleanup).should be_true 
    (Dir.exists? "cnfs/coredns-coredns").should be_false
    (File.exists?("cnfs/coredns-coredns/cnf-conformance.yml")).should be_false
    (File.exists?("cnfs/coredns-coredns/helm_chart/Chart.yaml")).should be_false
  end

  it "'CNFManager.sample_setup_args' should be able to deploy using a helm_directory", tags: "happy-path"  do
    args = Sam::Args.new
    CNFManager.sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", deploy_with_chart: false, args: args, verbose: true, wait_count: 0 )
    (Dir.exists? "cnfs/privileged-coredns-coredns").should be_true
    # should not clone
    (Dir.exists? "cnfs/privileged-coredns-coredns/privileged-coredns").should be_false
    (File.exists? "cnfs/privileged-coredns-coredns/cnf-conformance.yml").should be_true
    (File.exists? "cnfs/privileged-coredns-coredns/chart/Chart.yaml").should be_true
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample_privileged_cnf", verbose: true)
    (Dir.exists? "cnfs/privileged-coredns-coredns").should be_false
  end

  it "'cnf_destination_dir' should return the full path of the potential destination cnf directory based on the deployment name", tags: "WIP" do
    args = Sam::Args.new
    CNFManager.cnf_destination_dir("spec/fixtures/cnf-conformance.yml").should contain("/cnfs/coredns-coredns")
  end

  it "'CNFManager.cnf_config_list' should return a list of all of the config files from the cnf directory", tags: "happy-path"  do
    args = Sam::Args.new
    CNFManager.sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 1 )
    CNFManager.sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", args: args, verbose: true )
    CNFManager.cnf_config_list()[0].should contain("coredns-coredns/#{CONFIG_FILE}")
  end

  it "'CNFManager.helm_repo_add' should add a helm repo if the helm repo is valid", tags: "happy-path"  do
    args = Sam::Args.new
    CNFManager.sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: args, verbose: true, wait_count: 1 )
    # CNFManager.helm_repo_add.should eq(true)
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-conformance.yml"])
    CNFManager.helm_repo_add(args: args).should eq(true)
  end

  it "'CNFManager.helm_repo_add' should return false if the helm repo is invalid", tags: "happy-path"  do
    CNFManager.helm_repo_add("invalid", "invalid").should eq(false)
  end

  it "'CNFManager.validate_cnf_conformance_yml' (function) should pass, when a cnf has a valid config file yml", tags: ["unhappy-path", "validate_config"]  do
    args = Sam::Args.new(["cnf-config=sample-cnfs/sample-coredns-cnf/cnf-conformance.yml"])

    yml = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    LOGGING.info yml.inspect
    ("#{yml.get("release_name").as_s?}").should eq("coredns")

    valid, command_output = CNFManager.validate_cnf_conformance_yml(yml)

    (valid).should eq(true)
    (command_output).should eq (nil)
  end

  it "'CNFManager.validate_cnf_conformance_yml' (command) should pass, when a cnf has a valid config file yml", tags: ["unhappy-path", "validate_config"]  do
    response_s = `./cnf-conformance validate_config cnf-config=sample-cnfs/sample-coredns-cnf/cnf-conformance.yml`
    $?.success?.should be_true
    (/PASSED: CNF configuration validated/ =~ response_s).should_not be_nil
  end


  it "'CNFManager.validate_cnf_conformance_yml' (function) should warn, but be valid when a cnf config file yml has fields that are not a part of the validation type", tags: ["unhappy-path", "validate_config"]  do
    args = Sam::Args.new(["cnf-config=./spec/fixtures/cnf-conformance-unmapped-keys-and-subkeys.yml"])

    yml = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    LOGGING.info yml.inspect
    ("#{yml.get("release_name").as_s?}").should eq("coredns")

    status, warning_output = CNFManager.validate_cnf_conformance_yml(yml)

    LOGGING.warn "WARNING: #{warning_output}"

    (status).should eq(true)
    (warning_output).should_not be_nil
  end


  it "'CNFManager.validate_cnf_conformance_yml' (command) should warn, but be valid when a cnf config file yml has fields that are not a part of the validation type", tags: ["unhappy-path", "validate_config"]  do
    response_s = `./cnf-conformance validate_config cnf-config=spec/fixtures/cnf-conformance-unmapped-keys-and-subkeys.yml`
    $?.success?.should be_true
    (/WARNING: Unmapped cnf_conformance.yml keys. Please add them to the validator/ =~ response_s).should_not be_nil
    (/WARNING: helm_repository is unset or has unmapped subkeys. Please update your cnf_conformance.yml/ =~ response_s).should_not be_nil
    (/PASSED: CNF configuration validated/ =~ response_s).should_not be_nil
  end


  it "'CNFManager.validate_cnf_conformance_yml' (function) should fail when an invalid cnf config file yml is used", tags: ["unhappy-path", "validate_config"]  do
    args = Sam::Args.new(["cnf-config=spec/fixtures/cnf-conformance-invalid-and-unmapped-keys.yml"])

    yml = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    LOGGING.info yml.inspect
    ("#{yml.get("release_name").as_s?}").should eq("coredns")

    status, warning_output = CNFManager.validate_cnf_conformance_yml(yml)

    (status).should eq(false)
    (warning_output).should eq(nil)
  end

  it "'CNFManager.validate_cnf_conformance_yml' (command) should fail when an invalid cnf config file yml is used", tags: ["unhappy-path", "validate_config"]  do
    response_s = `./cnf-conformance validate_config cnf-config=spec/fixtures/cnf-conformance-invalid-and-unmapped-keys.yml`
    $?.success?.should be_true

    (/ERROR: cnf_conformance.yml field validation error/ =~ response_s).should_not be_nil
    (/FAILURE: Critical Error with CNF Configuration. Please review USAGE.md for steps to set up a valid CNF configuration file/ =~ response_s).should_not be_nil
  end

  it "'CNFManager.validate_cnf_conformance_yml' (command) should pass, for all sample-cnfs", tags: ["unhappy-path", "validate_config"]  do

    get_dirs = Dir.entries("sample-cnfs")
    dir_list = get_dirs - [".", ".."]
    dir_list.each do |dir|
      conformance_yml = "sample-cnfs/#{dir}/cnf-conformance.yml"
      response_s = `./cnf-conformance validate_config cnf-config=#{conformance_yml}`
      if (/FAILURE: Critical Error with CNF Configuration. Please review USAGE.md for steps to set up a valid CNF configuration file/ =~ response_s)
        LOGGING.info "\n #{conformance_yml}: #{response_s}"
      end
      (/PASSED: CNF configuration validated/ =~ response_s).should_not be_nil
    end
  end

  it "'CNFManager.validate_cnf_conformance_yml' (command) should pass, for all example-cnfs", tags: ["unhappy-path", "validate_config"]  do

    get_dirs = Dir.entries("example-cnfs")
    dir_list = get_dirs - [".", ".."]
    dir_list.each do |dir|
      conformance_yml = "example-cnfs/#{dir}/cnf-conformance.yml"
      response_s = `./cnf-conformance validate_config cnf-config=#{conformance_yml}`
      if (/FAILURE: Critical Error with CNF Configuration. Please review USAGE.md for steps to set up a valid CNF configuration file/ =~ response_s)
        LOGGING.info "\n #{conformance_yml}: #{response_s}"
      end
      (/PASSED: CNF configuration validated/ =~ response_s).should_not be_nil
    end
  end

  it "'CNFManager.helm_gives_k8s_warning?' should pass when k8s config = chmod 700"  do
    (CNFManager.helm_gives_k8s_warning?(true)).should be_false
  end

end



