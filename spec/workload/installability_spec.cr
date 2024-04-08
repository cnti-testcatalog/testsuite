require "../spec_helper"
require "colorize"

describe CnfTestSuite do
  before_all do
    result = ShellCmd.run_testsuite("samples_cleanup")
    result[:status].success?.should be_true
    result = ShellCmd.run_testsuite("setup")
  end

	it "'helm_deploy' should fail on a bad helm chart", tags: ["helm"] do
    result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/sample-bad-helm-deploy-repo verbose")
    result = ShellCmd.run_testsuite("helm_deploy verbose")
    result[:status].success?.should be_true
    (/(FAILED).*(Helm deploy failed)/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample-bad-helm-deploy-repo verbose")
  end

  it "'helm_deploy' should fail if command is not supplied cnf-config argument", tags: ["helm"] do
    result = ShellCmd.run_testsuite("helm_deploy")
    result[:status].success?.should be_true
    (/No cnf_testsuite.yml found! Did you run the setup task/ =~ result[:output]).should_not be_nil
  end

  it "'helm_chart_valid' should pass on a good helm chart", tags: ["helm"]  do
    result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml verbose")
    result[:status].success?.should be_true
    result = ShellCmd.run_testsuite("helm_chart_valid verbose")
    result[:status].success?.should be_true
    (/Lint Passed/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml verbose")
  end

  it "'helm_chart_valid' should fail on a bad helm chart", tags: ["helm"] do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample-bad_helm_coredns-cnf/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("helm_chart_valid")
      result[:status].success?.should be_true
      (/Lint Failed/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml verbose")
    end
  end

  it "'helm_chart_published' should pass on a good helm chart repo", tags: ["helm_chart_published"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample-coredns-cnf")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("helm_chart_published")
      result[:status].success?.should be_true
      (/(PASSED).*(Published Helm Chart Found)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample-coredns-cnf")
    end
  end

  it "'helm_chart_published' should fail on a bad helm chart repo", tags: ["helm_chart_published"] do
    begin
      result = ShellCmd.run("helm search repo stable/coredns", force_output: true)
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample-bad-helm-repo wait_count=0")
      result[:status].success?.should be_false
      result = ShellCmd.run("helm search repo stable/coredns", force_output: true)
      result = ShellCmd.run_testsuite("helm_chart_published verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(Published Helm Chart Not Found)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run("#{Helm::BinarySingleton.helm} repo remove badrepo")
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample-bad-helm-repo")
    end
  end
end
