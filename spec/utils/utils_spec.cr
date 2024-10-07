# coding: utf-8
require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/helmenv_setup.cr"
require "kubectl_client"
require "file_utils"
require "sam"
require "json"

describe "Utils" do
  before_all do
    result = ShellCmd.run_testsuite("setup")
    result[:status].success?.should be_true

    # Ensure a results file is present to test different scenarios
    CNFManager::Points::Results.ensure_results_file!
  end

  before_each do
    result = ShellCmd.run_testsuite("results_yml_cleanup")
  end
  after_each do
    result = ShellCmd.run_testsuite("results_yml_cleanup")
  end

  it "'toggle' should return a boolean for a toggle in the config.yml", tags: ["args"] do
    (toggle("wip")).should eq(false) 
  end

  it "'check_feature_level' should return the feature level for an argument variable", tags: ["args"]  do
    args = Sam::Args.new(["name", "arg1=1", "beta"])
    (check_feature_level(args)).should eq("beta")
    args = Sam::Args.new(["name", "arg1=1", "alpha"])
    (check_feature_level(args)).should eq("alpha")
    args = Sam::Args.new(["name", "arg1=1", "wip"])
    (check_feature_level(args)).should eq("wip")
    args = Sam::Args.new(["name", "arg1=1", "hi"])
    (check_feature_level(args)).should eq("ga")

  end

  it "'check_<x>' should return the feature level for an argument variable", tags: ["args"]  do
    (check_alpha).should be_false
    (check_beta).should be_false
    (check_wip).should be_false
  end

  it "'check_<x>(args)' should return the feature level for an argument variable", tags: ["args"]  do
    args = Sam::Args.new(["name", "arg1=1", "alpha"])
    (check_alpha(args)).should be_true
    (check_beta(args)).should be_true
    (check_wip(args)).should be_false
  end

  it "'check_cnf_config' should return the value for a cnf-config argument", tags: ["args"]  do
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-testsuite.yml"])
    #TODO make CNFManager.sample_setup_args accept the full path to the config yml instead of the directory
    (check_cnf_config(args)).should eq("./sample-cnfs/sample-generic-cnf")
  end
 

  it "'upsert_skipped_task' should put a 0 in the results file", tags: ["task_runner"]  do
    CNFManager::Points.clean_results_yml
    resp = upsert_skipped_task("ip_addresses","✖️  FAILED: IP addresses found", Time.utc)
    yaml = File.open("#{CNFManager::Points::Results.file}") do |file|
      YAML.parse(file)
    end
    (yaml["items"].as_a.find {|x| 
      x["name"] == "ip_addresses" && 
        x["points"] == CNFManager::Points.task_points("ip_addresses", CNFManager::ResultStatus::Skipped)
    }).should be_truthy

    (yaml["items"].as_a.find {|x| x["name"] == "ip_addresses" && x["points"] == 0 }).should be_truthy
  end

  it "'single_task_runner' should accept a cnf-config argument and apply a test to that cnf", tags: ["task_runner"]  do
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-testsuite.yml"])

    cli_hash = CNFManager.sample_setup_cli_args(args, false)
    CNFManager.sample_setup(cli_hash) if cli_hash["config_file"]
 
    task_response = CNFManager::Task.single_task_runner(args) do |args, config| 

      Log.info { "single_task_runner spec args #{args.inspect}" }

      white_list_container_names = config.common.white_list_container_names
      Log.info { "white_list_container_names #{white_list_container_names.inspect}" }
      violation_list = [] of String
      resource_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|

        privileged_list = KubectlClient::Get.privileged_containers
        resource_containers = KubectlClient::Get.resource_containers(resource["kind"],resource["name"],resource["namespace"])
        resource_containers_list = (JSON.parse(resource_containers.to_json).as_a).map { |element| element["name"] }
        # Only check the containers that are in the deployed helm chart or manifest
        (privileged_list & (resource_containers_list - white_list_container_names)).each do |x|
          violation_list << x
        end
        if violation_list.size > 0
          false
        else
          true
        end
      end
      Log.debug { "violator list: #{violation_list.flatten}" }
      emoji_security=""
      if resource_response 
        resp = upsert_passed_task("privileged_containers", "✔️  PASSED: No privileged containers", Time.utc)
      else
        resp = upsert_failed_task("privileged_containers", "✖️  FAILED: Found #{violation_list.size} privileged containers: #{violation_list.inspect}", Time.utc)
      end
      Log.info { resp }
      resp
    end
    (task_response).should eq("✔️  PASSED: No privileged containers")
  ensure
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
  end

  it "'single_task_runner' should put a 1 in the results file if it has an exception", tags: ["task_runner"]  do
    CNFManager::Points.clean_results_yml
    args = Sam::Args.new(["cnf-config=./cnf-testsuite.yml"])
    task_response = CNFManager::Task.single_task_runner(args) do
      cdir = FileUtils.pwd()
      response = String::Builder.new
      config = CNFInstall::Config.parse_cnf_config_from_file(CNFManager.ensure_cnf_testsuite_yml_path(args.named["cnf-config"].as(String)))
      helm_directory = config.deployments.get_deployment_param(:helm_directory) 
      if File.directory?(CNFManager.ensure_cnf_testsuite_dir(args.named["cnf-config"].as(String)) + helm_directory)
        Dir.cd(CNFManager.ensure_cnf_testsuite_dir(args.named["cnf-config"].as(String)) + helm_directory)
        Process.run("grep -r -P '^(?!.+0\.0\.0\.0)(?![[:space:]]*0\.0\.0\.0)(?!#)(?![[:space:]]*#)(?!\/\/)(?![[:space:]]*\/\/)(?!\/\\*)(?![[:space:]]*\/\\*)(.+([0-9]{1,3}[\.]){3}[0-9]{1,3})'", shell: true) do |proc|
          while line = proc.output.gets
            response << line
          end
        end
        Dir.cd(cdir)
        if response.to_s.size > 0
          resp = upsert_failed_task("ip_addresses","✖️  FAILED: IP addresses found", Time.utc)
        else
          resp = upsert_passed_task("ip_addresses", "✔️  PASSED: No IP addresses found", Time.utc)
        end
        resp
      else
        Dir.cd(cdir)
        resp = upsert_passed_task("ip_addresses", "✔️  PASSED: No IP addresses found", Time.utc)
      end
    end
    yaml = File.open("#{CNFManager::Points::Results.file}") do |file|
      YAML.parse(file)
    end
    (yaml["exit_code"]).should eq(2)
  end

  it "'all_cnfs_task_runner' should run a test against all cnfs in the cnfs directory if there is not cnf-config argument passed to it", tags: ["task_runner"]  do
    my_args = Sam::Args.new
      ShellCmd.cnf_setup("cnf-path=sample-cnfs/sample-generic-cnf")
      ShellCmd.cnf_setup("cnf-path=sample-cnfs/sample_privileged_cnf")
    task_response = CNFManager::Task.all_cnfs_task_runner(my_args) do |args, config|
      Log.info { "all_cnfs_task_runner spec args #{args.inspect}" }
      Log.for("verbose").info { "privileged_containers" } if check_verbose(args)
      white_list_container_names = config.common.white_list_container_names
      Log.for("verbose").info { "white_list_container_names #{white_list_container_names.inspect}" } if check_verbose(args)
      violation_list = [] of String
      resource_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|

        privileged_list = KubectlClient::Get.privileged_containers
        resource_containers = KubectlClient::Get.resource_containers(resource["kind"],resource["name"],resource["namespace"])
        resource_containers_list = (JSON.parse(resource_containers.to_json).as_a).map { |element| element["name"] }
        # Only check the containers that are in the deployed helm chart or manifest
        (privileged_list & (resource_containers_list - white_list_container_names)).each do |x|
          violation_list << x
        end
        if violation_list.size > 0
          false
        else
          true
        end
      end
      Log.debug { "violator list: #{violation_list.flatten}" }
      emoji_security=""
      if resource_response 
        resp = upsert_passed_task("privileged_containers", "✔️  PASSED: No privileged containers", Time.utc)
      else
        resp = upsert_failed_task("privileged_containers", "✖️  FAILED: Found #{violation_list.size} privileged containers: #{violation_list.inspect}", Time.utc)
      end
      resp
    end
    (task_response).should eq(["✔️  PASSED: No privileged containers", 
                               "✖️  FAILED: Found 1 privileged containers: [\"privileged-coredns\"]"])
  ensure
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample_privileged_cnf", verbose: true)
  end

  it "'task_runner' should run a test against a single cnf if passed a cnf-config argument even if there are multiple cnfs installed", tags: ["task_runner"]  do
    ShellCmd.cnf_setup("cnf-config=sample-cnfs/sample-generic-cnf/cnf-testsuite.yml")
    ShellCmd.cnf_setup("cnf-config=sample-cnfs/sample_privileged_cnf/cnf-testsuite.yml")
    result = ShellCmd.run_testsuite("privileged_containers")
    (/(FAILED).*(Found 1 privileged containers)/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-generic-cnf/cnf-testsuite.yml")
    result[:status].success?.should be_true
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample_privileged_cnf/cnf-testsuite.yml")
    result[:status].success?.should be_true
  end

  it "'logger' command line logger level setting via config.yml", tags: ["logger"]  do
    # NOTE: the config.yml file is in the root of the repo directory. 
    # as written this test depends on they key loglevel being set to 'info' in that config.yml
    result = ShellCmd.run_testsuite("test")
    result[:status].success?.should be_true
    (/DEBUG -- cnf-testsuite: debug test/ =~ result[:output]).should be_nil
    (/INFO -- cnf-testsuite: info test/ =~ result[:output]).should_not be_nil
    (/WARN -- cnf-testsuite: warn test/ =~ result[:output]).should_not be_nil
    (/ERROR -- cnf-testsuite: error test/ =~ result[:output]).should_not be_nil
  end

  it "'logger' command line logger level setting works", tags: ["logger"]  do
    # Note: implicitly tests the override of config.yml if it exist in repo root
    result = ShellCmd.run_testsuite("-l debug test")
    result[:status].success?.should be_true
    (/DEBUG -- cnf-testsuite: debug test/ =~ result[:output]).should_not be_nil
  end

  it "'logger' LOGLEVEL NO underscore environment variable level setting works", tags: ["logger"]  do
    # Note: implicitly tests the override of config.yml if it exist in repo root
    result = ShellCmd.run_testsuite("test", cmd_prefix: "unset LOG_LEVEL; LOGLEVEL=DEBUG")
    result[:status].success?.should be_true
    (/DEBUG -- cnf-testsuite: debug test/ =~ result[:output]).should_not be_nil
  end

  it "'logger' LOG_LEVEL WITH underscore environment variable level setting works", tags: ["logger"]  do
    # Note: implicitly tests the override of config.yml if it exist in repo root
    result = ShellCmd.run_testsuite("test", cmd_prefix: "LOG_LEVEL=DEBUG")
    result[:status].success?.should be_true
    (/DEBUG -- cnf-testsuite: debug test/ =~ result[:output]).should_not be_nil
  end

  it "'logger' command line level setting overrides environment variable", tags: ["logger"]  do
    result = ShellCmd.run_testsuite("-l error test", cmd_prefix: "LOG_LEVEL=DEBUG")
    result[:status].success?.should be_true
    (/DEBUG -- cnf-testsuite: debug test/ =~ result[:output]).should be_nil
    (/INFO -- cnf-testsuite: info test/ =~ result[:output]).should be_nil
    (/WARN -- cnf-testsuite: warn test/ =~ result[:output]).should be_nil
    (/ERROR -- cnf-testsuite: error test/ =~ result[:output]).should_not be_nil
  end

  it "'logger' defaults to error when level set is missplled", tags: ["logger"]  do
    # Note: implicitly tests the override of config.yml if it exist in repo root
    result = ShellCmd.run_testsuite("test", cmd_prefix: "unset LOG_LEVEL; LOG_LEVEL=DEGUB")
    result[:status].success?.should be_true
    (/ERROR -- cnf-testsuite: Invalid logging level set. defaulting to ERROR/ =~ result[:output]).should_not be_nil
  end

  it "'logger' or verbose output should be shown when verbose flag is set", tags: ["logger"] do
    ShellCmd.cnf_setup("cnf-path=sample-cnfs/sample-coredns-cnf")
    result = ShellCmd.run_testsuite("helm_deploy verbose", cmd_prefix: "LOG_LEVEL=info")
    puts result[:output]
    result[:status].success?.should be_true
    (/helm_deploy args/ =~ result[:output]).should_not be_nil
  ensure
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-coredns-cnf", verbose: true)
  end

  it "'logger' should write logs to the file when LOG_PATH is set", tags: ["logger"] do
    response_s = `LOG_PATH=spec-test-testsuite.log ./cnf-testsuite test`
    $?.success?.should be_true
    (/ERROR -- cnf-testsuite: error test/ =~ response_s).should be_nil
    File.exists?("spec-test-testsuite.log").should be_true
    (/ERROR -- cnf-testsuite: error test/ =~ File.read("spec-test-testsuite.log")).should_not be_nil
  ensure
    if File.exists?("spec-test-testsuite.log")
      File.delete("spec-test-testsuite.log")
    end
  end

  it "'#update_yml' should update the value for a key in a yml file", tags: ["logger"]  do
    begin
    update_yml("spec/fixtures/cnf-testsuite.yml", "release_name", "coredns --set worker-node='kind-control-plane'")
    yaml = File.open("spec/fixtures/cnf-testsuite.yml") do |file|
      YAML.parse(file)
    end
    (yaml["release_name"]).should eq("coredns --set worker-node='kind-control-plane'")
    ensure
      update_yml("spec/fixtures/cnf-testsuite.yml", "release_name", "coredns")
    end
  end

  it "spec directory should have tags for all of the specs", tags: ["spec-tags"]  do
    response = String::Builder.new
    Process.run("grep -r -I -P '^ *it \"(?!.*tags(.*\"))' ./spec", shell: true) do |proc|
      while line = proc.output.gets
        response << line
        Log.info { "#{line}" }
      end
    end
    (response.to_s.size > 0).should be_false
  end

end
