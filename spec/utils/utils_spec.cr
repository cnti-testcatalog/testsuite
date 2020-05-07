require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "file_utils"
require "sam"

describe "Utils" do
  before_each do
    `crystal src/cnf-conformance.cr results_yml_cleanup`
  end
  after_each do
    `crystal src/cnf-conformance.cr results_yml_cleanup`
  end

  it "'create_results_yml' should create a results yaml file" do
    create_results_yml
    yaml = File.open("#{LOGFILE}") do |file|
      YAML.parse(file)
    end
    (yaml["name"]).should eq("cnf conformance")
  end

  it "'final_cnf_results_yml' should return the named yaml file" do
    yml_name = create_final_results_yml_name
    unless File.exists?(yml_name)
      File.open(yml_name, "w") do |f| 
        YAML.dump(template_results_yml, f)
      end 
    end
    (final_cnf_results_yml).should eq(yml_name)
  end

  it "'points_yml' should parse and return the points yaml file" do
    (points_yml.find {|x| x["name"] =="liveness"}).should be_truthy 
  end

  it  "'task_points' should return the amount of points for a passing test" do
    # default
    (task_points("liveness")).should eq(5)
    # assigned
    (task_points("increase_capacity")).should eq(10)
  end

  it  "'task_points(, false)' should return the amount of points for a failing test" do
    # default
    (task_points("liveness", false)).should eq(-1)
    # assigned
    (task_points("increase_capacity", false)).should eq(-5)
  end

  it "'failed_task' should find and update an existing task in the file" do
    create_results_yml
    failed_task("liveness", "FAILURE: No livenessProbe found")

    yaml = File.open("#{LOGFILE}") do |file|
      YAML.parse(file)
    end
    puts yaml.inspect
    (yaml["items"].as_a.find {|x| x["name"] == "liveness" && x["points"] == task_points("liveness", false)}).should be_truthy
  end

  it "'passed_task' should find and update an existing task in the file" do
    create_results_yml
    passed_task("liveness", "PASSED: livenessProbe found")

    yaml = File.open("#{LOGFILE}") do |file|
      YAML.parse(file)
    end
    puts yaml.inspect
    (yaml["items"].as_a.find {|x| x["name"] == "liveness" && x["points"] == task_points("liveness")}).should be_truthy
  end

  it "'task_required' should return if the passed task is required" do
    create_results_yml
    (task_required("privileged")).should be_true
  end

  it "'failed_required_tasks' should return a list of failed required tasks" do
    create_results_yml
    failed_task("privileged", "FAILURE: Privileged container found")
    (failed_required_tasks).should eq(["privileged"])
  end

  it "'upsert_task' should find and update an existing task in the file" do
    create_results_yml
    upsert_task("liveness", PASSED, task_points("liveness"))
    yaml = File.open("#{LOGFILE}") do |file|
      YAML.parse(file)
    end
    # puts yaml["items"].as_a.inspect
    (yaml["items"].as_a.find {|x| x["name"] == "liveness" && x["points"] == task_points("liveness")}).should be_truthy
  end

  it "'total_points' should sum the total amount of points in the results"do
    create_results_yml
    upsert_task("liveness", PASSED, task_points("liveness"))
    (total_points).should eq(5)
  end

  it "'tasks_by_tag' should return the tasks assigned to a tag"do
    create_results_yml
    (tasks_by_tag("configuration_lifecycle")).should eq(["reset_cnf", "check_reaped", "versioned_helm_chart", "ip_addresses", "liveness", "readiness", "no_volume_with_configuration", "rolling_update"])
    (tasks_by_tag("does-not-exist")).should eq([] of YAML::Any) 
  end

  it "'all_task_test_names' should return all tasks names"do
    create_results_yml
    (all_task_test_names()).should eq(["reasonable_image_size", "reasonable_startup_time","cni_spec", "api_snoop_alpha", "api_snoop_beta", "api_snoop_general_apis", "reset_cnf", "check_reaped", "privileged", "shells", "protected_access", "increase_capacity", "decrease_capacity", "small_autoscaling", "large_autoscaling", "network_chaos", "external_retry", "versioned_helm_chart", "ip_addresses", "liveness", "readiness", "no_volume_with_configuration", "rolling_update", "fluentd_traffic", "jaeger_traffic", "prometheus_traffic", "opentelemetry_compatible",  "openmetric_compatible", "helm_deploy", "install_script_helm", "helm_chart_valid", "helm_chart_published", "hardware_affinity", "static_accessing_hardware", "dynamic_accessing_hardware", "direct_hugepages", "performance", "k8s_conformance"])
  end

  it "'all_result_test_names' should return the tasks assigned to a tag"do
    create_results_yml
    upsert_task("liveness", PASSED, task_points("liveness"))
    (all_result_test_names(LOGFILE)).should eq(["liveness"])
  end
  it "'results_by_tag' should return a list of results by tag"do
    create_results_yml
    upsert_task("liveness", PASSED, task_points("liveness"))
    (results_by_tag("configuration_lifecycle")).should eq([{"name" => "liveness", "status" => "passed", "points" => 5}])
    (results_by_tag("does-not-exist")).should eq([] of YAML::Any) 
  end

  it "'toggle' should return a boolean for a toggle in the config.yml"do
    (toggle("wip")).should eq(false) 
  end

  it "'check_feature_level' should return the feature level for an argument variable" do
    args = Sam::Args.new(["name", "arg1=1", "beta"])
    (check_feature_level(args)).should eq("beta")
    args = Sam::Args.new(["name", "arg1=1", "alpha"])
    (check_feature_level(args)).should eq("alpha")
    args = Sam::Args.new(["name", "arg1=1", "wip"])
    (check_feature_level(args)).should eq("wip")
    args = Sam::Args.new(["name", "arg1=1", "hi"])
    (check_feature_level(args)).should eq("ga")

  end

  it "'check_<x>' should return the feature level for an argument variable" do
    # (check_ga).should be_false
    (check_alpha).should be_false
    (check_beta).should be_false
    (check_wip).should be_false
  end

  it "'check_<x>(args)' should return the feature level for an argument variable" do
    args = Sam::Args.new(["name", "arg1=1", "alpha"])
    (check_alpha(args)).should be_true
    (check_beta(args)).should be_true
    (check_wip(args)).should be_false
  end
end
