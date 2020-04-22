require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
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

  it "'points_yml' should parse and return the points yaml file" do
    (points_yml.find {|x| x["name"] =="liveness"}).should be_truthy 
  end

  it  "'passing_task' should return the amount of points for a passing test" do
    (passing_task("liveness")).should eq(5)
  end

  it  "'failing_task' should return the amount of points for a failing test" do
    (failing_task("liveness")).should eq(-1)
  end

  it "'upsert_task' should find and update an existing task in the file" do
    create_results_yml
    upsert_task("liveness", PASSED, passing_task("liveness"))
    yaml = File.open("#{LOGFILE}") do |file|
      YAML.parse(file)
    end
    # puts yaml["items"].as_a.inspect
    (yaml["items"].as_a.find {|x| x["name"] == "liveness" && x["points"] == passing_task("liveness")}).should be_truthy
  end

  it "'total_points' should sum the total amount of points in the results"do
    create_results_yml
    upsert_task("liveness", PASSED, passing_task("liveness"))
    (total_points).should eq(5)
  end

  it "'tasks_by_tag' should return the tasks assigned to a tag"do
    create_results_yml
    (tasks_by_tag("configuration_lifecycle")).should eq(["reset_cnf", "check_reaped", "versioned_helm_chart", "ip_addresses", "liveness", "readiness", "no_volume_with_configuration", "rolling_update"])
    (tasks_by_tag("does-not-exist")).should eq([] of YAML::Any) 
  end

  it "'results_by_tag' should return a list of results by tag"do
    create_results_yml
    (results_by_tag("configuration_lifecycle")).should_not eq([] of YAML::Any)
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
