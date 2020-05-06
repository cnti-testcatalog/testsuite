require "./spec_helper"
require "../src/tasks/utils/utils.cr"
require "colorize"

describe CnfConformance do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr samples_cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr setup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr sample_coredns_with_wait_setup`
    $?.success?.should be_true
  end

  after_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr samples_cleanup`
    $?.success?.should be_true
  end

  it "'all' should run the whole test suite" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    # Test the binary
    build_s = `crystal build src/cnf-conformance.cr`
    $?.success?.should be_true
    puts build_s 
    response_s = `./cnf-conformance all`
    puts response_s
    $?.success?.should be_true
    (/PASSED: Helm readiness probe found/ =~ response_s).should_not be_nil
    (/PASSED: Helm liveness probe/ =~ response_s).should_not be_nil
    (/Lint Passed/ =~ response_s).should_not be_nil
    (/PASSED: Replicas increased to 3/ =~ response_s).should_not be_nil
    (/PASSED: Replicas decreased to 1/ =~ response_s).should_not be_nil
    (/PASSED: Published Helm Chart Repo added/ =~ response_s).should_not be_nil
    (/Final score:/ =~ response_s).should_not be_nil
    (all_result_test_names(final_cnf_results_yml)).should eq(["privileged", "increase_capacity", "decrease_capacity", "ip_addresses", "liveness", "readiness", "install_script_helm", "helm_chart_valid", "helm_chart_published", "reasonable_image_size", "reasonable_startup_time"])
  end

   it "'scalability' should run all of the scalability tests" do
     # puts `pwd` 
     # puts `echo $KUBECONFIG`
     response_s = `crystal src/cnf-conformance.cr setup`
     puts response_s
     response_s = `crystal src/cnf-conformance.cr scalability`
     puts response_s
       $?.success?.should be_true
     (/PASSED: Replicas increased to 3/ =~ response_s).should_not be_nil
     (/PASSED: Replicas decreased to 1/ =~ response_s).should_not be_nil
   end


end
