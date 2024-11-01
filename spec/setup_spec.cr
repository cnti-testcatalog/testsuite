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

  it "'cnf_setup/cnf_cleanup' should install/cleanup with cnf-path arg as alias for cnf-config", tags: ["setup"] do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=example-cnfs/coredns/cnf-testsuite.yml")
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup a cnf with a cnf-testsuite.yml", tags: ["setup"] do
    begin
      result = ShellCmd.new_cnf_setup("cnf-config=example-cnfs/coredns/cnf-testsuite.yml")
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should work with cnf-testsuite.yml that has no directory associated with it", tags: ["setup"] do
    begin
      #TODO force cnfs/<name> to be deployment name and not the directory name
      result = ShellCmd.new_cnf_setup("cnf-config=spec/fixtures/cnf-testsuite.yml verbose")
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup with helm_directory that descends multiple directories", tags: ["setup"] do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=sample-cnfs/multi_helm_directories/cnf-testsuite.yml")
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should properly install/uninstall old versions of cnf configs", tags: ["setup"] do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=spec/fixtures/cnf-testsuite-v1-example.yml")
      result[:status].success?.should be_true
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup' should fail if another CNF is already installed", tags: ["setup"] do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=sample-cnfs/sample_coredns/cnf-testsuite.yml")
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
      result = ShellCmd.new_cnf_setup("cnf-path=sample-cnfs/sample-minimal-cnf/cnf-testsuite.yml")
      (/A CNF is already set up. Setting up multiple CNFs is not allowed./ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
      ShellCmd.new_cnf_cleanup(expect_failure: true)
    end
  end
end
