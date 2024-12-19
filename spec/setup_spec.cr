require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "kubectl_client"
require "helm"
require "file_utils"
require "sam"

describe "Installation" do
  after_each do
    result = ShellCmd.environment_cleanup()
  end

  it "'install_dependencies' should install all cnf-testsuite dependencies before installing cnfs", tags:["installation"]  do
    result = ShellCmd.run_testsuite("install_dependencies")
    result[:status].success?.should be_true
    (/Dependency installation complete/ =~ result[:output]).should_not be_nil
  end

  it "'cnf_install' should pass with a minimal cnf-testsuite.yml", tags:["installation"] do
    result = ShellCmd.cnf_install("cnf-path=./sample-cnfs/sample-minimal-cnf/")
    (/CNF installation complete/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.cnf_uninstall()
    (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
  end

  it "'cnf_install/cnf_uninstall' should install/uninstall with cnf-config arg as an alias for cnf-path", tags:["installation"] do
    result = ShellCmd.cnf_install("cnf-config=./sample-cnfs/sample-minimal-cnf/")
    (/CNF installation complete/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.cnf_uninstall()
    (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
  end

  it "'cnf_install/cnf_uninstall' should install/uninstall with cnf-path arg as an alias for cnf-config", tags:["installation"] do
    begin
      result = ShellCmd.cnf_install("cnf-path=example-cnfs/coredns/cnf-testsuite.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_uninstall()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_install/cnf_uninstall' should fail on incorrect config", tags:["installation"] do
    begin
      result = ShellCmd.cnf_install("cnf-path=spec/fixtures/sample-bad-config.yml", expect_failure: true)
      (/Error during parsing CNF config/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_uninstall(expect_failure: true)
    end
  end

  it "'cnf_install/cnf_uninstall' should install/uninstall a cnf with a cnf-testsuite.yml", tags:["installation"] do
    begin
      result = ShellCmd.cnf_install("cnf-config=example-cnfs/coredns/cnf-testsuite.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_uninstall()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_install/cnf_uninstall' should work with cnf-testsuite.yml that has no directory associated with it", tags:["installation"] do
    begin
      #TODO force cnfs/<name> to be deployment name and not the directory name
      result = ShellCmd.cnf_install("cnf-config=spec/fixtures/cnf-testsuite.yml verbose")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_uninstall()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_install/cnf_uninstall' should install/uninstall with helm_directory that descends multiple directories", tags:["installation"] do
    begin
      result = ShellCmd.cnf_install("cnf-path=sample-cnfs/multi_helm_directories/cnf-testsuite.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_uninstall()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_install/cnf_uninstall' should properly install/uninstall old versions of cnf configs", tags:["installation"] do
    begin
      result = ShellCmd.cnf_install("cnf-path=spec/fixtures/cnf-testsuite-v1-example.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_uninstall()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_install' should fail if another CNF is already installed", tags:["installation"] do
    begin
      result = ShellCmd.cnf_install("cnf-path=sample-cnfs/sample_coredns/cnf-testsuite.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
      result = ShellCmd.cnf_install("cnf-path=sample-cnfs/sample-minimal-cnf/cnf-testsuite.yml")
      (/A CNF is already set up. Setting up multiple CNFs is not allowed./ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_uninstall()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_install/cnf_uninstall' should install/uninstall a cnf with multiple deployments", tags:["installation"] do
    begin
      result = ShellCmd.cnf_install("cnf-path=sample-cnfs/sample_multiple_deployments/cnf-testsuite.yml")
      (/All "coredns" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/All "memcached" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/All "nginx" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_uninstall()
      (/Successfully uninstalled helm deployment "coredns"/ =~ result[:output]).should_not be_nil
      (/Successfully uninstalled helm deployment "memcached"/ =~ result[:output]).should_not be_nil
      (/Successfully uninstalled helm deployment "nginx"/ =~ result[:output]).should_not be_nil
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_install/cnf_uninstall' should install/uninstall deployment with mixed installation methods", tags:["installation"] do
    begin
      result = ShellCmd.cnf_install("cnf-path=sample-cnfs/sample-nginx-redis/cnf-testsuite.yml")
      (/All "nginx" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/All "redis" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_uninstall()
      (/Successfully uninstalled helm deployment "nginx"/ =~ result[:output]).should_not be_nil
      (/Successfully uninstalled manifest deployment "redis"/ =~ result[:output]).should_not be_nil
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_install/cnf_uninstall' should handle partial deployment failures gracefully", tags:["installation"] do
    begin
      result = ShellCmd.cnf_install("cnf-path=sample-cnfs/sample-partial-deployment-failure/cnf-testsuite.yml", expect_failure: true)
      (/All "nginx" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/Deployment of "coredns" failed during CNF installation/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_uninstall()
      (/Successfully uninstalled helm deployment "nginx"/ =~ result[:output]).should_not be_nil
    end
  end

  it "'cnf_install' should detect and report conflicts between deployments", tags:["installation"] do
    begin
      result = ShellCmd.cnf_install("cnf-path=spec/fixtures/sample-conflicting-deployments.yml", expect_failure: true)
      (/Deployment names should be unique/ =~ result[:output]).should_not be_nil
    ensure
      ShellCmd.cnf_uninstall(expect_failure: true)
    end
  end

  it "'cnf_install' should correctly handle deployment priority", tags:["installation"] do
    # (kosstennbl) ELK stack requires to be installed with specific order, otherwise it would give errors
    begin
      result = ShellCmd.cnf_install("cnf-path=sample-cnfs/sample-elk-stack/cnf-testsuite.yml timeout=600")
      result[:status].success?.should be_true
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.cnf_uninstall()
      result[:status].success?.should be_true
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end
end
