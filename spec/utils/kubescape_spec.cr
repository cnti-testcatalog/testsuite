require "../spec_helper"
require "../../src/tasks/utils/kubescape.cr"

describe "K8sInstrumentation" do


  it "'#scan and #result_by_test_name' should return the results of a kubescape scan", tags: ["kubescape"]  do
    LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
    Kubescape.scan
    results_json = Kubescape.parse
    test_json = Kubescape.result_by_test_name(results_json, "Network policies")
    (test_json).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
  end

  it "'#scan and #test_alerts' should return the alerts of a test", tags: ["kubescape"]  do
    LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
    Kubescape.scan
    results_json = Kubescape.parse
    test_json = Kubescape.result_by_test_name(results_json, "Network policies")
    score_json = Kubescape.score_by_test_name(results_json, "Network policies")
    (score_json).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
  end

  it "'#scan and #test_alerts' should return the alerts of a test", tags: ["kubescape"]  do
    LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
    Kubescape.scan
    results_json = Kubescape.parse
    test_json = Kubescape.result_by_test_name(results_json, "Network policies")
    test_json = Kubescape.alerts_by_test(test_json)
    (test_json[0]).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
  end


end

