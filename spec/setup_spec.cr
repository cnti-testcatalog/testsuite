require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "kubectl_client"
require "helm"
require "file_utils"
require "sam"

describe "Setup" do

  after_each do
    result = ShellCmd.run_testsuite("cleanup")
    result[:status].success?.should be_true
  end

  it "'setup' should completely setup the cnf testsuite environment before installing cnfs", tags: ["setup"]  do
    result = ShellCmd.run_testsuite("setup")
    result[:status].success?.should be_true
    (/Setup complete/ =~ result[:output]).should_not be_nil
  end

  it "'generate_config' should generate a cnf-testsuite.yml for a helm chart", tags: ["setup-generate"]  do
    result = ShellCmd.run_testsuite("setup")
    result = ShellCmd.run_testsuite("generate_config config-src=stable/coredns output-file=./cnf-testsuite-test.yml")
    result[:status].success?.should be_true

    yaml = File.open("./cnf-testsuite-test.yml") do |file|
      YAML.parse(file)
    end
    Log.debug { "test yaml: #{yaml}" }
    result = ShellCmd.run("cat ./cnf-testsuite-test.yml", force_output: true)
    (yaml["helm_chart"] == "stable/coredns").should be_true
  ensure
    result = ShellCmd.run("rm ./cnf-testsuite-test.yml", force_output: true)
  end

  it "'generate_config' should generate a cnf-testsuite.yml for a helm directory", tags: ["setup-generate"]  do
    result = ShellCmd.run_testsuite("setup")
    result = ShellCmd.run_testsuite("generate_config config-src=sample-cnfs/k8s-sidecar-container-pattern/chart output-file=./cnf-testsuite-test.yml")
    result[:status].success?.should be_true

    yaml = File.open("./cnf-testsuite-test.yml") do |file|
      YAML.parse(file)
    end
    Log.debug { "test yaml: #{yaml}" }
    result = ShellCmd.run("cat ./cnf-testsuite-test.yml", force_output: true)
    (yaml["helm_directory"] == "sample-cnfs/k8s-sidecar-container-pattern/chart").should be_true
  ensure
    result = ShellCmd.run("rm ./cnf-testsuite-test.yml", force_output: true)
  end

  it "'generate_config' should generate a cnf-testsuite.yml for a manifest directory", tags: ["setup-generate"]  do
    result = ShellCmd.run_testsuite("setup")
    result = ShellCmd.run_testsuite("generate_config config-src=sample-cnfs/k8s-non-helm/manifests output-file=./cnf-testsuite-test.yml")
    result[:status].success?.should be_true

    yaml = File.open("./cnf-testsuite-test.yml") do |file|
      YAML.parse(file)
    end
    Log.debug { "test yaml: #{yaml}" }
    result = ShellCmd.run("cat ./cnf-testsuite-test.yml", force_output: true)
    (yaml["manifest_directory"] == "sample-cnfs/k8s-non-helm/manifests").should be_true
  ensure
    result = ShellCmd.run("rm ./cnf-testsuite-test.yml", force_output: true)
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup with cnf-path arg as alias for cnf-config", tags: ["setup"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=example-cnfs/coredns/cnf-testsuite.yml")
      result[:status].success?.should be_true
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=example-cnfs/coredns/cnf-testsuite.yml")
      result[:status].success?.should be_true
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup a cnf with a cnf-testsuite.yml", tags: ["setup"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=example-cnfs/coredns/cnf-testsuite.yml")
      result[:status].success?.should be_true
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=example-cnfs/coredns/cnf-testsuite.yml")
      result[:status].success?.should be_true
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should work with cnf-testsuite.yml that has no directory associated with it", tags: ["setup"] do
    begin
      #TODO force cnfs/<name> to be deployment name and not the directory name
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=spec/fixtures/cnf-testsuite.yml verbose")
      result[:status].success?.should be_true
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure

      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=spec/fixtures/cnf-testsuite.yml verbose")
      result[:status].success?.should be_true
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup with helm_directory that descends multiple directories", tags: ["setup"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/multi_helm_directories/cnf-testsuite.yml")
      result[:status].success?.should be_true
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/multi_helm_directories/cnf-testsuite.yml")
      result[:status].success?.should be_true
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end
end
