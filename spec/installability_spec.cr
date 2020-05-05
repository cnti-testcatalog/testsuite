require "./spec_helper"
require "colorize"

describe CnfConformance do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`

    `crystal src/cnf-conformance.cr samples_cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr configuration_file_setup`

    # `crystal src/cnf-conformance.cr setup`
    # $?.success?.should be_true
  end

  it "'install_script_helm' should fail if install script does not have helm" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    # `crystal src/cnf-conformance.cr cleanup`
    # $?.success?.should be_true
    `crystal src/cnf-conformance.cr sample_coredns_source_setup`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr install_script_helm`
    #puts response_s
    $?.success?.should be_true
    (/FAILURE: Helm not found in supplied install script/ =~ response_s).should_not be_nil
    `crystal src/cnf-conformance.cr sample_coredns_source_cleanup`
  end

  it "'helm_deploy' should fail on a bad helm chart", tags: "helm" do
    `crystal src/cnf-conformance.cr setup`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr helm_deploy yml-file=sample-cnfs/sample-bad-helm-deploy-repo/cnf-conformance.yml verbose`
    $?.success?.should be_true
    (/FAILURE: Helm did not deploy properly/ =~ response_s).should_not be_nil
    `crystal src/cnf-conformance.cr cleanup`
  end

  it "'helm_deploy' should fail if command is not supplied yml-file argument", tags: "helm" do
    `crystal src/cnf-conformance.cr setup`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr helm_deploy`
    $?.success?.should be_true
    (/No cnf_conformance.yml found! Did you run the setup task/ =~ response_s).should_not be_nil
    `crystal src/cnf-conformance.cr cleanup`
  end

  it "'helm_deploy' should pass if command is supplied yml-file argument", tags: "helm" do
    `crystal src/cnf-conformance.cr setup`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr helm_deploy yml-file=sample-cnfs/sample-generic-cnf/cnf-conformance.yml verbose`
    puts response_s
    $?.success?.should be_true
    (/PASSED: Helm was deployed successfully/ =~ response_s).should_not be_nil
    `crystal src/cnf-conformance.cr cleanup`
  end

  it "'helm_chart_valid' should pass on a good helm chart" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    # `crystal src/cnf-conformance.cr cleanup`
    # $?.success?.should be_true
    `crystal src/cnf-conformance.cr sample_coredns_setup`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr helm_chart_valid`
    puts response_s
    $?.success?.should be_true
    (/Lint Passed/ =~ response_s).should_not be_nil
  end

  it "'helm_chart_valid' should fail on a bad helm chart" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr sample_coredns_cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr bad_helm_cnf_setup`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr helm_chart_valid`
    puts response_s
    $?.success?.should be_true
    (/Lint Failed/ =~ response_s).should_not be_nil
    `crystal src/cnf-conformance.cr bad_helm_cnf_cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr sample_coredns_setup`
    $?.success?.should be_true
  end

  it "'helm_chart_published' should pass on a good helm chart repo", tags: "helm_chart_published" do
    `crystal src/cnf-conformance.cr cnf_setup cnf-path=sample-cnfs/sample-coredns-cnf`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr helm_chart_published`
    puts response_s
    $?.success?.should be_true
    (/Helm Chart Repo added/ =~ response_s).should_not be_nil
  end

  it "'helm_chart_published' should fail on a bad helm chart repo", tags: "helm_chart_published" do
    `crystal src/cnf-conformance.cr cnf_cleanup cnf-path=sample-cnfs/sample-coredns-cnf`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr cnf_setup cnf-path=sample-cnfs/sample-bad-helm-repo`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr helm_chart_published`
    puts response_s
    $?.success?.should be_true
    (/Helm Chart Repo failed to add/ =~ response_s).should_not be_nil
    `crystal src/cnf-conformance.cr cnf_cleanup cnf-path=sample-cnfs/sample-bad-helm-repo`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr cnf_setup cnf-path=sample-cnfs/sample-coredns-cnf`
    $?.success?.should be_true
  end
end
