# coding: utf-8
require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "file_utils"
require "sam"

describe "Utils" do
  before_each do
    `./cnf-conformance results_yml_cleanup`
  end
  after_each do
    `./cnf-conformance results_yml_cleanup`
  end

  it "'#Results.file' should return the name of the current yaml file"  do
    clean_results_yml
    yaml = File.open("#{Results.file}") do |file|
      YAML.parse(file)
    end
    (yaml["name"]).should eq("cnf conformance")
    (yaml["exit_code"]).should eq(0) 
  end

  it "'CNFManager.final_cnf_results_yml' should return the latest time stamped results file"  do
    (CNFManager.final_cnf_results_yml).should contain("cnf-conformance-results")
  end

  it "'points_yml' should parse and return the points yaml file"  do
    (points_yml.find {|x| x["name"] =="liveness"}).should be_truthy 
  end

  it  "'task_points' should return the amount of points for a passing test" do
    # default
    (task_points("liveness")).should eq(5)
    # assigned
    (task_points("increase_capacity")).should eq(10)
  end

  it  "'task_points(, false)' should return the amount of points for a failing test"  do
    # default
    (task_points("liveness", false)).should eq(-1)
    # assigned
    (task_points("increase_capacity", false)).should eq(-5)
  end

  it "'failed_task' should find and update an existing task in the file"  do
    clean_results_yml
    failed_task("liveness", "FAILURE: No livenessProbe found")

    yaml = File.open("#{Results.file}") do |file|
      YAML.parse(file)
    end
    LOGGING.info yaml.inspect
    (yaml["items"].as_a.find {|x| x["name"] == "liveness" && x["points"] == task_points("liveness", false)}).should be_truthy
  end

  it "'passed_task' should find and update an existing task in the file"  do
    clean_results_yml
    passed_task("liveness", "PASSED: livenessProbe found")

    yaml = File.open("#{Results.file}") do |file|
      YAML.parse(file)
    end
    LOGGING.info yaml.inspect
    (yaml["items"].as_a.find {|x| x["name"] == "liveness" && x["points"] == task_points("liveness")}).should be_truthy
  end

  it "'task_required' should return if the passed task is required"  do
    clean_results_yml
    (task_required("privileged")).should be_true
  end

  it "'failed_required_tasks' should return a list of failed required tasks"  do
    clean_results_yml
    failed_task("privileged", "FAILURE: Privileged container found")
    (failed_required_tasks).should eq(["privileged"])
  end

  it "'upsert_task' insert task in the results file"  do
    clean_results_yml
    upsert_task("liveness", PASSED, task_points("liveness"))
    yaml = File.open("#{Results.file}") do |file|
      YAML.parse(file)
    end
    # LOGGING.debug yaml["items"].as_a.inspect
    (yaml["items"].as_a.find {|x| x["name"] == "liveness" && x["points"] == task_points("liveness")}).should be_truthy
  end

  it "'upsert_task' should find and update an existing task in the file"  do
    clean_results_yml
    upsert_task("liveness", PASSED, task_points("liveness"))
    upsert_task("liveness", PASSED, task_points("liveness"))
    yaml = File.open("#{Results.file}") do |file|
      YAML.parse(file)
    end
    # LOGGING.debug yaml["items"].as_a.inspect
    (yaml["items"].as_a.find {|x| x["name"] == "liveness" && x["points"] == task_points("liveness")}).should be_truthy
    (total_points).should eq(5)
  end

  it "'total_points' should sum the total amount of points in the results" do
    clean_results_yml
    upsert_task("liveness", PASSED, task_points("liveness"))
    (total_points).should eq(5)
  end

  it "'tasks_by_tag' should return the tasks assigned to a tag" do
    clean_results_yml
    (tasks_by_tag("configuration_lifecycle")).should eq(["ip_addresses", "liveness", "readiness", "rolling_update", "rolling_downgrade", "rolling_version_change", "rollback", "nodeport_not_used", "hardcoded_ip_addresses_in_k8s_runtime_configuration"])
    (tasks_by_tag("does-not-exist")).should eq([] of YAML::Any) 
  end

  it "'all_task_test_names' should return all tasks names" do
    clean_results_yml
    (all_task_test_names()).should eq(["reasonable_image_size", "reasonable_startup_time", "privileged", "increase_capacity", "decrease_capacity", "network_chaos", "ip_addresses", "liveness", "readiness", "rolling_update", "rolling_downgrade", "rolling_version_change", "rollback", "nodeport_not_used", "hardcoded_ip_addresses_in_k8s_runtime_configuration", "helm_deploy", "install_script_helm", "helm_chart_valid", "helm_chart_published", "chaos_network_loss", "chaos_cpu_hog", "chaos_container_kill", "volume_hostpath_not_found", "no_local_volume_configuration"])
  end

  it "'all_result_test_names' should return the tasks assigned to a tag" do
    clean_results_yml
    upsert_task("liveness", PASSED, task_points("liveness"))
    (all_result_test_names(Results.file)).should eq(["liveness"])
  end
  it "'results_by_tag' should return a list of results by tag" do
    clean_results_yml
    upsert_task("liveness", PASSED, task_points("liveness"))
    (results_by_tag("configuration_lifecycle")).should eq([{"name" => "liveness", "status" => "passed", "points" => 5}])
    (results_by_tag("does-not-exist")).should eq([] of YAML::Any) 
  end

  it "'toggle' should return a boolean for a toggle in the config.yml" do
    (toggle("wip")).should eq(false) 
  end

  it "'check_feature_level' should return the feature level for an argument variable"  do
    args = Sam::Args.new(["name", "arg1=1", "beta"])
    (check_feature_level(args)).should eq("beta")
    args = Sam::Args.new(["name", "arg1=1", "alpha"])
    (check_feature_level(args)).should eq("alpha")
    args = Sam::Args.new(["name", "arg1=1", "wip"])
    (check_feature_level(args)).should eq("wip")
    args = Sam::Args.new(["name", "arg1=1", "hi"])
    (check_feature_level(args)).should eq("ga")

  end

  it "'check_<x>' should return the feature level for an argument variable"  do
    # (check_ga).should be_false
    (check_alpha).should be_false
    (check_beta).should be_false
    (check_wip).should be_false
  end

  it "'check_<x>(args)' should return the feature level for an argument variable"  do
    args = Sam::Args.new(["name", "arg1=1", "alpha"])
    (check_alpha(args)).should be_true
    (check_beta(args)).should be_true
    (check_wip(args)).should be_false
  end
  # it "'LOGGGING.level' should be Severity::ERROR when checked in"  do
  #   (LOGGING.level).should eq(Logger::ERROR)
  # end
  it "'check_cnf_config' should return the value for a cnf-config argument"  do
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-conformance.yml"])
    #TODO make CNFManager.sample_setup_args accept the full path to the config yml instead of the directory
    (check_cnf_config(args)).should eq("./sample-cnfs/sample-generic-cnf")
  end

  it "'check_all_cnf_args' should return the value for a cnf-config argument"  do
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-conformance.yml"])
    #TODO make CNFManager.sample_setup_args accept the full path to the config yml instead of the directory
    (check_all_cnf_args(args)).should eq({"./sample-cnfs/sample-generic-cnf", true})
  end
  it "'check_cnf_config_then_deploy' should accept a cnf-config argument"  do
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-conformance.yml"])
    check_cnf_config_then_deploy(args)
    CNFManager.cnf_config_list()[0].should contain("coredns-coredns/#{CONFIG_FILE}")
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
  end

  it "'single_task_runner' should accept a cnf-config argument and apply a test to that cnf"  do
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-conformance.yml"])
    check_cnf_config_then_deploy(args)
    task_response = single_task_runner(args) do
      config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
      helm_chart_container_name = config.get("helm_chart_container_name").as_s
      privileged_response = `kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[?(@.securityContext.privileged==true)].name}'`
      privileged_list = privileged_response.to_s.split(" ").uniq
      LOGGING.info "privileged_list #{privileged_list}"
      if privileged_list.select {|x| x == helm_chart_container_name}.size > 0
        resp = "✖️  FAILURE: Found privileged containers: #{privileged_list.inspect}".colorize(:red)
      else
        resp = "✔️  PASSED: No privileged containers".colorize(:green)
      end
      LOGGING.info resp
      resp
    end
    (task_response).should eq("✔️  PASSED: No privileged containers".colorize(:green))
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
  end

  it "'single_task_runner' should put a -1 in the results file if it has an exception"  do
    clean_results_yml
    args = Sam::Args.new(["cnf-config=./cnf-conformance.yml"])
    task_response = single_task_runner(args) do
      cdir = FileUtils.pwd()
      response = String::Builder.new
      config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
      helm_directory = "#{config.get("helm_directory").as_s?}" 
      if File.directory?(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)) + helm_directory)
        Dir.cd(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)) + helm_directory)
        Process.run("grep -r -P '^(?!.+0\.0\.0\.0)(?![[:space:]]*0\.0\.0\.0)(?!#)(?![[:space:]]*#)(?!\/\/)(?![[:space:]]*\/\/)(?!\/\\*)(?![[:space:]]*\/\\*)(.+([0-9]{1,3}[\.]){3}[0-9]{1,3})'", shell: true) do |proc|
          while line = proc.output.gets
            response << line
          end
        end
        Dir.cd(cdir)
        if response.to_s.size > 0
          resp = upsert_failed_task("ip_addresses","✖️  FAILURE: IP addresses found")
        else
          resp = upsert_passed_task("ip_addresses", "✔️  PASSED: No IP addresses found")
        end
        resp
      else
        Dir.cd(cdir)
        resp = upsert_passed_task("ip_addresses", "✔️  PASSED: No IP addresses found")
      end
    end
    yaml = File.open("#{Results.file}") do |file|
      YAML.parse(file)
    end
    (yaml["exit_code"]).should eq(1)
  end

  it "'all_cnfs_task_runner' should run a test against all cnfs in the cnfs directory if there is not cnf-config argument passed to it"  do
    my_args = Sam::Args.new
    CNFManager.sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: my_args)
    CNFManager.sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", args: my_args )
    task_response = all_cnfs_task_runner(my_args) do |args|
      LOGGING.info("all_cnfs_task_runner spec args #{args.inspect}")
      # config = cnf_conformance_yml(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
      config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
      helm_chart_container_name = config.get("helm_chart_container_name").as_s
      privileged_response = `kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[?(@.securityContext.privileged==true)].name}'`
      privileged_list = privileged_response.to_s.split(" ").uniq
      LOGGING.info "privileged_list #{privileged_list}"
      if privileged_list.select {|x| x == helm_chart_container_name}.size > 0
        resp = "✖️  FAILURE: Found privileged containers: #{privileged_list.inspect}".colorize(:red)
      else
        resp = "✔️  PASSED: No privileged containers".colorize(:green)
      end
      LOGGING.info resp
      resp
    end
    (task_response).should eq(["✔️  PASSED: No privileged containers".colorize(:green), "✔️  PASSED: No privileged containers".colorize(:green)])
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample_privileged_cnf", verbose: true)
  end

  it "'task_runner' should run a test against a single cnf if passed a cnf-config argument even if there are multiple cnfs installed"  do
    my_args = Sam::Args.new
    CNFManager.sample_setup_args(sample_dir: "sample-cnfs/sample-generic-cnf", args: my_args)
    CNFManager.sample_setup_args(sample_dir: "sample-cnfs/sample_privileged_cnf", args: my_args )
    installed_args = Sam::Args.new(["cnf-config=./cnfs/coredns-coredns/cnf-conformance.yml"])
    task_response = task_runner(installed_args) do |args|
      LOGGING.info("task_runner spec args #{args.inspect}")
      # config = cnf_conformance_yml(CNFManager.ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
      config = CNFManager.parsed_config_file(CNFManager.ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
      helm_chart_container_name = config.get("helm_chart_container_name").as_s
      privileged_response = `kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[?(@.securityContext.privileged==true)].name}'`
      privileged_list = privileged_response.to_s.split(" ").uniq
      LOGGING.info "privileged_list #{privileged_list}"
      if privileged_list.select {|x| x == helm_chart_container_name}.size > 0
        resp = "✖️  FAILURE: Found privileged containers: #{privileged_list.inspect}".colorize(:red)
      else
        resp = "✔️  PASSED: No privileged containers".colorize(:green)
      end
      LOGGING.info resp
      resp
    end
    (task_response).should eq("✔️  PASSED: No privileged containers".colorize(:green))
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample_privileged_cnf", verbose: true)
  end

  it "'generate_version' should return the current version of the cnf_conformance library" do
    (generate_version).should_not eq("")
  end

  it "'logger' command line logger level setting via config.yml", tags: ["logger", "happy-path"]  do
    # NOTE: the config.yml file is in the root of the repo directory. 
    # as written this test depends on they key loglevel being set to 'info' in that config.yml
    response_s = `./cnf-conformance test`
    $?.success?.should be_true
    (/DEBUG -- cnf-conformance: debug test/ =~ response_s).should be_nil
    (/INFO -- cnf-conformance: info test/ =~ response_s).should_not be_nil
    (/WARN -- cnf-conformance: warn test/ =~ response_s).should_not be_nil
    (/ERROR -- cnf-conformance: error test/ =~ response_s).should_not be_nil
  end

  it "'logger' command line logger level setting works", tags: ["logger", "happy-path"]  do
    # Note: implicitly tests the override of config.yml if it exist in repo root
    response_s = `./cnf-conformance -l debug test`
    LOGGING.info response_s
    $?.success?.should be_true
    (/DEBUG -- cnf-conformance: debug test/ =~ response_s).should_not be_nil
  end

  it "'logger' LOGLEVEL NO underscore environment variable level setting works", tags: ["logger", "happy-path"]  do
    # Note: implicitly tests the override of config.yml if it exist in repo root
    response_s = `unset LOG_LEVEL; LOGLEVEL=DEBUG ./cnf-conformance test`
    $?.success?.should be_true
    (/DEBUG -- cnf-conformance: debug test/ =~ response_s).should_not be_nil
  end

  it "'logger' LOG_LEVEL WITH underscore environment variable level setting works", tags: ["logger", "happy-path"]  do
    # Note: implicitly tests the override of config.yml if it exist in repo root
    response_s = `LOG_LEVEL=DEBUG ./cnf-conformance test`
    $?.success?.should be_true
    (/DEBUG -- cnf-conformance: debug test/ =~ response_s).should_not be_nil
  end

  it "'logger' command line level setting overrides environment variable", tags: ["logger", "happy-path"]  do
    response_s = `LOGLEVEL=DEBUG ./cnf-conformance -l error test`
    $?.success?.should be_true
    (/DEBUG -- cnf-conformance: debug test/ =~ response_s).should be_nil
    (/INFO -- cnf-conformance: info test/ =~ response_s).should be_nil
    (/WARN -- cnf-conformance: warn test/ =~ response_s).should be_nil
    (/ERROR -- cnf-conformance: error test/ =~ response_s).should_not be_nil
  end

  it "'logger' defaults to error when level set is missplled", tags: ["logger"]  do
    # Note: implicitly tests the override of config.yml if it exist in repo root
    response_s = `unset LOG_LEVEL; LOGLEVEL=DEGUB ./cnf-conformance test`
    $?.success?.should be_true
    (/ERROR -- cnf-conformance: Invalid logging level set. defaulting to ERROR/ =~ response_s).should_not be_nil
  end

  it "'logger' or verbose output should be shown when verbose flag is set", tags: ["logger"] do
    response_s = `./cnf-conformance helm_deploy verbose`
    LOGGING.info response_s
    puts response_s
    $?.success?.should be_true
    (/INFO -- cnf-conformance-verbose: helm_deploy/ =~ response_s).should_not be_nil
  end

  it "'#update_yml' should update the value for a key in a yml file"  do
    begin
    update_yml("spec/fixtures/cnf-conformance.yml", "release_name", "coredns --set worker-node='kind-control-plane'")
    yaml = File.open("spec/fixtures/cnf-conformance.yml") do |file|
      YAML.parse(file)
    end
    (yaml["release_name"]).should eq("coredns --set worker-node='kind-control-plane'")
    ensure
      update_yml("spec/fixtures/cnf-conformance.yml", "release_name", "coredns")
    end
  end

end

