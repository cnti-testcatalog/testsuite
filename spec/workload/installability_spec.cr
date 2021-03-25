require "../spec_helper"
require "colorize"

describe CnfConformance do
  before_all do
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
    LOGGING.info `./cnf-conformance setup`
  end

  it "'install_script_helm' should fail if install script does not have helm", tags: ["helm"]  do
    LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf-source/cnf-conformance.yml verbose wait_count=0`
    $?.success?.should be_true
    response_s =  `./cnf-conformance install_script_helm`
    LOGGING.info response_s
    $?.success?.should be_true
    (/FAILED: Helm not found in supplied install script/ =~ response_s).should_not be_nil
    `./cnf-conformance sample_coredns_source_cleanup`
  end

	it "'helm_deploy' should fail on a bad helm chart", tags: ["helm"] do
    response_s = `./cnf-conformance helm_deploy destructive cnf-config=sample-cnfs/sample-bad-helm-deploy-repo/cnf-conformance.yml verbose`
    LOGGING.info response_s
    $?.success?.should be_true
    (/FAILED: Helm deploy failed/ =~ response_s).should_not be_nil
  end

  it "'helm_deploy' should fail if command is not supplied cnf-config argument", tags: ["helm"] do
    response_s = `./cnf-conformance helm_deploy destructive`
    LOGGING.info response_s
    $?.success?.should be_true
    (/No cnf_conformance.yml found! Did you run the setup task/ =~ response_s).should_not be_nil
  end

  it "'helm_deploy' should pass if command is supplied cnf-config argument with helm_chart declared", tags: ["helm"]  do
    response_s = `./cnf-conformance helm_deploy destructive cnf-config=sample-cnfs/sample_coredns/cnf-conformance.yml verbose`
    $?.success?.should be_true
    LOGGING.info response_s
    (/PASSED: Helm deploy successful/ =~ response_s).should_not be_nil
  end

  it "'helm_deploy' should pass if command is supplied cnf-config argument without helm_chart declared", tags: ["helm"]  do
    response_s = `./cnf-conformance helm_deploy destructive cnf-config=sample-cnfs/sample_coredns_chart_directory/cnf-conformance.yml verbose`
    $?.success?.should be_true
    LOGGING.info response_s
    (/PASSED: Helm deploy successful/ =~ response_s).should_not be_nil
  end


  it "'helm_chart_valid' should pass on a good helm chart", tags: ["helm"]  do
    LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-conformance.yml verbose wait_count=0`
    $?.success?.should be_true
    response_s = `./cnf-conformance helm_chart_valid verbose`
    LOGGING.info response_s
    $?.success?.should be_true
    (/Lint Passed/ =~ response_s).should_not be_nil
  end

  it "'helm_chart_valid' should fail on a bad helm chart", tags: ["helm"] do
    # LOGGING.debug `pwd` 
    # LOGGING.debug `echo $KUBECONFIG`
    begin
      `./cnf-conformance sample_coredns_cleanup force=true`
      $?.success?.should be_true
      LOGGING.info `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample-bad_helm_coredns-cnf/cnf-conformance.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-conformance helm_chart_valid`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Lint Failed/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance bad_helm_cnf_cleanup force=true`
      `./cnf-conformance cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-conformance.yml verbose wait_count=0`
    end
  end

  it "'helm_chart_published' should pass on a good helm chart repo", tags: ["helm_chart_published"]  do
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

  it "'helm_chart_published' should fail on a bad helm chart repo", tags: ["helm_chart_published"] do
    begin
      LOGGING.info "search command: #{`helm search repo stable/coredns`}"
      # LOGGING.info `#{CNFSingleton.helm} repo remove stable`
      # LOGGING.info "search command: #{`helm search repo stable/coredns`}"
      LOGGING.info `./cnf-conformance cnf_setup cnf-path=sample-cnfs/sample-bad-helm-repo wait_count=0`
      $?.success?.should be_true
      LOGGING.info "search command: #{`helm search repo stable/coredns`}"
      response_s = `./cnf-conformance helm_chart_published verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Published Helm Chart Not Found/ =~ response_s).should_not be_nil
    ensure
      `#{CNFSingleton.helm} repo remove badrepo`
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample-bad-helm-repo`
    end
  end
end
