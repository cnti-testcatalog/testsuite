require "./spec_helper"
require "colorize"
require "../src/tasks/utils.cr"
require "file_utils"
require "sam"

describe "Utils" do
  before_each do
    `rm results.yml`
  end
  after_each do
    `rm results.yml`
  end

  it "'create_results_yml' should create a results yaml file" do
    create_results_yml
    yaml = File.open("results.yml") do |file|
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
    yaml = File.open("results.yml") do |file|
      YAML.parse(file)
    end
    # puts yaml["items"].as_a.inspect
    (yaml["items"].as_a.find {|x| x["name"] == "liveness" && x["points"] == passing_task("liveness")}).should be_truthy
  end

end
