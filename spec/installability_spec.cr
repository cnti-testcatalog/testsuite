require "./spec_helper"
require "colorize"

describe CnfConformance do
  before_all do
    # LOGGING.debug `pwd` 
    # LOGGING.debug `echo $KUBECONFIG`

    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
    # `./cnf-conformance configuration_file_setup`
    LOGGING.info `./cnf-conformance setup`
    # $?.success?.should be_true
  end

  it "'install_script_helm' should fail if install script does not have helm", tags: "happy-path"  do
    # LOGGING.debug `pwd` 
    # LOGGING.debug `echo $KUBECONFIG`
    # `./cnf-conformance cleanup`
    # $?.success?.should be_true
    `./cnf-conformance sample_coredns_source_setup`
    $?.success?.should be_true
    response_s = `./cnf-conformance install_script_helm`
    #LOGGING.info response_s
    $?.success?.should be_true
    (/FAILURE: Helm not found in supplied install script/ =~ response_s).should_not be_nil
    `./cnf-conformance sample_coredns_source_cleanup`
  end

	it "'helm_deploy' should fail on a bad helm chart", tags: "helm" do
    response_s = `./cnf-conformance helm_deploy cnf-config=sample-cnfs/sample-bad-helm-deploy-repo/cnf-conformance.yml verbose`
    $?.success?.should be_true
    LOGGING.info response_s
    (/FAILURE: Helm deploy failed/ =~ response_s).should_not be_nil
  end

  it "'helm_deploy' should fail if command is not supplied cnf-config argument", tags: "helm" do
    response_s = `./cnf-conformance helm_deploy`
    LOGGING.info response_s
    $?.success?.should be_true
    (/No cnf_conformance.yml found! Did you run the setup task/ =~ response_s).should_not be_nil
  end

  it "'helm_deploy' should pass if command is supplied cnf-config argument with helm_chart declared", tags: ["helm", "happy-path"]  do
    response_s = `./cnf-conformance helm_deploy cnf-config=sample-cnfs/sample_coredns/cnf-conformance.yml verbose`
    $?.success?.should be_true
    LOGGING.info response_s
    (/PASSED: Helm deploy successful/ =~ response_s).should_not be_nil
  end

  it "'helm_deploy' should pass if command is supplied cnf-config argument without helm_chart declared", tags: ["helm", "happy-path"]  do
    response_s = `./cnf-conformance helm_deploy cnf-config=sample-cnfs/sample_coredns_chart_directory/cnf-conformance.yml verbose`
    $?.success?.should be_true
    LOGGING.info response_s
    (/PASSED: Helm deploy successful/ =~ response_s).should_not be_nil
  end


  it "'helm_chart_valid' should pass on a good helm chart", tags: "happy-path"  do
    # LOGGING.debug `pwd` 
    # LOGGING.debug `echo $KUBECONFIG`
    # `./cnf-conformance cleanup`
    # $?.success?.should be_true
    `./cnf-conformance sample_coredns_setup`
    $?.success?.should be_true
    response_s = `./cnf-conformance helm_chart_valid`
    LOGGING.info response_s
    $?.success?.should be_true
    (/Lint Passed/ =~ response_s).should_not be_nil
  end

  it "'helm_chart_valid' should fail on a bad helm chart" do
    # LOGGING.debug `pwd` 
    # LOGGING.debug `echo $KUBECONFIG`
    begin
      `./cnf-conformance sample_coredns_cleanup force=true`
      $?.success?.should be_true
      `./cnf-conformance bad_helm_cnf_setup`
      $?.success?.should be_true
      response_s = `./cnf-conformance helm_chart_valid`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Lint Failed/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance bad_helm_cnf_cleanup force=true`
      `./cnf-conformance sample_coredns_setup`
    end
  end

  it "'helm_chart_published' should pass on a good helm chart repo", tags: ["helm_chart_published","happy-path"]  do
    begin
      `./cnf-conformance cnf_setup cnf-path=sample-cnfs/sample-coredns-cnf`
      $?.success?.should be_true
      response_s = `./cnf-conformance helm_chart_published`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Published Helm Chart Found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample-coredns-cnf`
    end
  end

  it "'helm_chart_published' should fail on a bad helm chart repo", tags: "helm_chart_published" do
    begin
      `#{CNFSingleton.helm} repo remove stable`
      `./cnf-conformance cnf_setup cnf-path=sample-cnfs/sample-bad-helm-repo`
      $?.success?.should be_true
      response_s = `./cnf-conformance helm_chart_published`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILURE: Published Helm Chart Not Found/ =~ response_s).should_not be_nil
    ensure
      `#{CNFSingleton.helm} repo add stable https://kubernetes-charts.storage.googleapis.com`
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample-bad-helm-repo`
    end
  end

end
