require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "kubectl_client"
require "helm"
require "file_utils"
require "sam"

describe "Setup" do
  after_each do
    result = ShellCmd.environment_cleanup()
  end

  it "'setup' should completely setup the cnf testsuite environment before installing cnfs", tags: ["setup"]  do
    result = ShellCmd.run_testsuite("setup")
    result[:status].success?.should be_true
    (/Setup complete/ =~ result[:output]).should_not be_nil
  end

  it "'cnf_setup' should pass with a minimal cnf-testsuite.yml", tags: ["setup"] do
    result = ShellCmd.cnf_setup("cnf-path=./sample-cnfs/sample-minimal-cnf/")
    (/CNF installation complete/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.cnf_cleanup()
    (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup with cnf-config arg as an alias for cnf-path", tags: ["setup"] do
    result = ShellCmd.cnf_setup("cnf-config=./sample-cnfs/sample-minimal-cnf/")
    (/CNF installation complete/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.cnf_cleanup()
    (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup with cnf-path arg as an alias for cnf-config", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=example-cnfs/coredns/cnf-testsuite.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_cleanup()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should fail on incorrect config", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=spec/fixtures/sample-bad-config.yml", expect_failure: true)
      (/Error during parsing CNF config/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_cleanup(expect_failure: true)
    end
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup a cnf with a cnf-testsuite.yml", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-config=example-cnfs/coredns/cnf-testsuite.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_cleanup()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should work with cnf-testsuite.yml that has no directory associated with it", tags: ["setup"] do
    begin
      #TODO force cnfs/<name> to be deployment name and not the directory name
      result = ShellCmd.cnf_setup("cnf-config=spec/fixtures/cnf-testsuite.yml verbose")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_cleanup()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup with helm_directory that descends multiple directories", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=sample-cnfs/multi_helm_directories/cnf-testsuite.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_cleanup()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should properly install/uninstall old versions of cnf configs", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=spec/fixtures/cnf-testsuite-v1-example.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_cleanup()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup' should fail if another CNF is already installed", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=sample-cnfs/sample_coredns/cnf-testsuite.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
      result = ShellCmd.cnf_setup("cnf-path=sample-cnfs/sample-minimal-cnf/cnf-testsuite.yml")
      (/A CNF is already set up. Setting up multiple CNFs is not allowed./ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_cleanup()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup a cnf with multiple deployments", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=sample-cnfs/sample_multiple_deployments/cnf-testsuite.yml")
      (/All "coredns" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/All "memcached" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/All "nginx" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_cleanup()
      (/Successfully uninstalled helm deployment "coredns"/ =~ result[:output]).should_not be_nil
      (/Successfully uninstalled helm deployment "memcached"/ =~ result[:output]).should_not be_nil
      (/Successfully uninstalled helm deployment "nginx"/ =~ result[:output]).should_not be_nil
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup deployment with mixed installation methods", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=sample-cnfs/sample-nginx-redis/cnf-testsuite.yml")
      (/All "nginx" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/All "redis" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_cleanup()
      (/Successfully uninstalled helm deployment "nginx"/ =~ result[:output]).should_not be_nil
      (/Successfully uninstalled manifest deployment "redis"/ =~ result[:output]).should_not be_nil
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup/cnf_cleanup' should handle partial deployment failures gracefully", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=sample-cnfs/sample-partial-deployment-failure/cnf-testsuite.yml", expect_failure: true)
      (/All "nginx" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/Deployment of "coredns" failed during CNF installation/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_cleanup()
      (/Successfully uninstalled helm deployment "nginx"/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_setup' should detect and report conflicts between deployments", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=spec/fixtures/sample-conflicting-deployments.yml", expect_failure: true)
      (/Deployment names should be unique/ =~ result[:output]).should_not be_nil
    ensure
      ShellCmd.cnf_cleanup(expect_failure: true)
    end
  end
end
