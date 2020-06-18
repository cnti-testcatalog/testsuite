require "./spec_helper"
require "../src/tasks/utils/utils.cr"
require "colorize"

describe CnfConformance do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
    `./cnf-conformance setup`
    $?.success?.should be_true
    # `./cnf-conformance sample_coredns_with_wait_setup`
    # $?.success?.should be_true
  end

  after_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
  end

  it "'all' should run the whole test suite", tags: "happy-path" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    # Test the binary
    # Build should already be present
    # build_s = `crystal build src/cnf-conformance.cr`
    # $?.success?.should be_true
    # puts build_s 
    `./cnf-conformance samples_cleanup`
    response_s = `./cnf-conformance all cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-conformance.yml`
    puts response_s
    $?.success?.should be_true
    (/PASSED: Helm readiness probe found/ =~ response_s).should_not be_nil
    (/PASSED: Helm liveness probe/ =~ response_s).should_not be_nil
    (/Lint Passed/ =~ response_s).should_not be_nil
    (/PASSED: Replicas increased to 3/ =~ response_s).should_not be_nil
    (/PASSED: Replicas decreased to 1/ =~ response_s).should_not be_nil
    (/PASSED: Published Helm Chart Found/ =~ response_s).should_not be_nil
    (/Final score:/ =~ response_s).should_not be_nil
    (all_result_test_names(final_cnf_results_yml)).should eq(["volume_hostpath_not_found", "privileged", "increase_capacity", "decrease_capacity", "ip_addresses", "liveness", "readiness", "rolling_update", "nodeport_not_used", "hardcoded_ip_addresses_in_k8s_runtime_configuration", "install_script_helm", "helm_chart_valid", "helm_chart_published","helm_deploy", "reasonable_image_size", "reasonable_startup_time", "chaos_network_loss", "chaos_cpu_hog", "chaos_container_kill"])
  end

  it "'scalability' should run all of the scalability tests", tags: "happy-path"  do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `./cnf-conformance samples_cleanup`
    response_s = `./cnf-conformance setup`
    puts response_s
    `./cnf-conformance sample_coredns_with_wait_setup`
    $?.success?.should be_true
    response_s = `./cnf-conformance scalability`
    puts response_s
    $?.success?.should be_true
    (/PASSED: Replicas increased to 3/ =~ response_s).should_not be_nil
    (/PASSED: Replicas decreased to 1/ =~ response_s).should_not be_nil
  end
end
