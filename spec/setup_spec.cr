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

  # (svteb) TODO: delete in #2171
  it "'cnf_setup/cnf_cleanup' should install/cleanup with cnf-path arg as alias for cnf-config", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=example-cnfs/coredns/cnf-testsuite.yml")
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=example-cnfs/coredns/cnf-testsuite.yml")
      result[:status].success?.should be_true
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: delete in #2171
  it "'cnf_setup/cnf_cleanup' should install/cleanup a cnf with a cnf-testsuite.yml", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-config=example-cnfs/coredns/cnf-testsuite.yml")
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=example-cnfs/coredns/cnf-testsuite.yml")
      result[:status].success?.should be_true
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: delete in #2171
  it "'cnf_setup/cnf_cleanup' should work with cnf-testsuite.yml that has no directory associated with it", tags: ["setup"] do
    begin
      #TODO force cnfs/<name> to be deployment name and not the directory name
      result = ShellCmd.cnf_setup("cnf-config=spec/fixtures/cnf-testsuite.yml verbose")
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure

      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=spec/fixtures/cnf-testsuite.yml verbose")
      result[:status].success?.should be_true
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: delete in #2171
  it "'cnf_setup/cnf_cleanup' should install/cleanup with helm_directory that descends multiple directories", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=sample-cnfs/multi_helm_directories/cnf-testsuite.yml")
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/multi_helm_directories/cnf-testsuite.yml")
      result[:status].success?.should be_true
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: delete in #2171
  it "'cnf_setup/cnf_cleanup' should properly install/uninstall old versions of cnf configs", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=spec/fixtures/cnf-testsuite-v1-example.yml")
      result[:status].success?.should be_true
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=spec/fixtures/cnf-testsuite-v1-example.yml")
      result[:status].success?.should be_true
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: delete in #2171
  it "'cnf_setup' should fail if another CNF is already installed", tags: ["setup"] do
    begin
      result = ShellCmd.cnf_setup("cnf-path=sample-cnfs/sample_coredns/cnf-testsuite.yml")
      (/Successfully setup coredns/ =~ result[:output]).should_not be_nil
      result = ShellCmd.cnf_setup("cnf-path=sample-cnfs/sample-minimal-cnf/cnf-testsuite.yml")
      (/A CNF is already set up. Setting up multiple CNFs is not allowed./ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_coredns/cnf-testsuite.yml")
      result[:status].success?.should be_true
      (/Successfully cleaned up/ =~ result[:output]).should_not be_nil
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample-minimal-cnf/cnf-testsuite.yml")
    end
  end

  # (svteb) TODO: delete in #2171
  it "'cnf_setup' should pass with a minimal cnf-testsuite.yml", tags: ["setup"] do
    ShellCmd.cnf_setup("cnf-path=./sample-cnfs/sample-minimal-cnf/")
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample-minimal-cnf/")
  end

  # (svteb) TODO: delete in #2171
  it "'cnf_setup' should support cnf-config as an alias for cnf-path", tags: ["setup"] do
    ShellCmd.cnf_setup("cnf-config=./sample-cnfs/sample-minimal-cnf/")
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample-minimal-cnf/")
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171
  it "'cnf_setup' should pass with a minimal cnf-testsuite.yml", tags: ["setup"] do
    result = ShellCmd.new_cnf_setup("cnf-path=./sample-cnfs/sample-minimal-cnf/")
    (/CNF installation complete/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.new_cnf_cleanup()
    (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171
  it "'cnf_setup/cnf_cleanup' should install/cleanup with cnf-config arg as an alias for cnf-path", tags: ["setup"] do
    result = ShellCmd.new_cnf_setup("cnf-config=./sample-cnfs/sample-minimal-cnf/")
    (/CNF installation complete/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.new_cnf_cleanup()
    (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171
  it "'cnf_setup/cnf_cleanup' should install/cleanup with cnf-path arg as an alias for cnf-config", tags: ["setup"] do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=example-cnfs/coredns/cnf-testsuite.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171
  it "'cnf_setup/cnf_cleanup' should fail on incorrect config", tags: ["setup"] do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=sample-cnfs/sample-bad-config/cnf-testsuite.yml", expect_failure: true)
      (/Error during parsing CNF config/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup(expect_failure: true)
    end
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171
  it "'cnf_setup/cnf_cleanup' should install/cleanup a cnf with a cnf-testsuite.yml", tags: ["setup"] do
    begin
      result = ShellCmd.new_cnf_setup("cnf-config=example-cnfs/coredns/cnf-testsuite.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171
  it "'cnf_setup/cnf_cleanup' should work with cnf-testsuite.yml that has no directory associated with it", tags: ["setup"] do
    begin
      #TODO force cnfs/<name> to be deployment name and not the directory name
      result = ShellCmd.new_cnf_setup("cnf-config=spec/fixtures/cnf-testsuite.yml verbose")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171
  it "'cnf_setup/cnf_cleanup' should install/cleanup with helm_directory that descends multiple directories", tags: ["setup"] do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=sample-cnfs/multi_helm_directories/cnf-testsuite.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171
  it "'cnf_setup/cnf_cleanup' should properly install/uninstall old versions of cnf configs", tags: ["setup"] do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=spec/fixtures/cnf-testsuite-v1-example.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171
  it "'cnf_setup' should fail if another CNF is already installed", tags: ["setup"] do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=sample-cnfs/sample_coredns/cnf-testsuite.yml")
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
      result = ShellCmd.new_cnf_setup("cnf-path=sample-cnfs/sample-minimal-cnf/cnf-testsuite.yml")
      (/A CNF is already set up. Setting up multiple CNFs is not allowed./ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171 AND ADD <, tags: ["setup"]>
  it "'cnf_setup/cnf_cleanup' should install/cleanup a cnf with multiple deployments" do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=sample-cnfs/sample_multiple_deployments/cnf-testsuite.yml")
      (/All "coredns" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/All "memcached" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/All "nginx" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/Successfully uninstalled helm deployment "coredns"/ =~ result[:output]).should_not be_nil
      (/Successfully uninstalled helm deployment "memcached"/ =~ result[:output]).should_not be_nil
      (/Successfully uninstalled helm deployment "nginx"/ =~ result[:output]).should_not be_nil
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171 AND ADD <, tags: ["setup"]>
  it "'cnf_setup/cnf_cleanup' should install/cleanup deployment with mixed installation methods" do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=sample-cnfs/sample-nginx-redis/cnf-testsuite.yml")
      (/All "nginx" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/All "redis" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/CNF installation complete/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/Successfully uninstalled helm deployment "nginx"/ =~ result[:output]).should_not be_nil
      (/Successfully uninstalled manifest deployment "redis"/ =~ result[:output]).should_not be_nil
      (/All CNF deployments were uninstalled/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171 AND ADD <, tags: ["setup"]>
  it "'cnf_setup/cnf_cleanup' should handle partial deployment failures gracefully" do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=sample-cnfs/sample-partial-deployment-failure/cnf-testsuite.yml", expect_failure: true)
      (/All "nginx" deployment resources are up/ =~ result[:output]).should_not be_nil
      (/Deployment of "coredns" failed during CNF installation/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.new_cnf_cleanup()
      (/Successfully uninstalled helm deployment "nginx"/ =~ result[:output]).should_not be_nil
    end
  end

  # (svteb) TODO: change new_cnf_setup/new_cnf_cleanup to cnf_setup/cnf_cleanup in #2171 AND ADD <, tags: ["setup"]>
  it "'cnf_setup' should detect and report conflicts between deployments" do
    begin
      result = ShellCmd.new_cnf_setup("cnf-path=sample-cnfs/sample-conflicting-deployments/cnf-testsuite.yml", expect_failure: true)
      (/Deployment names should be unique/ =~ result[:output]).should_not be_nil
    ensure
      ShellCmd.new_cnf_cleanup(expect_failure: true)
    end
  end
end
