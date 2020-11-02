require "../spec_helper"
require "../../src/tasks/utils/utils.cr"
require "colorize"

describe "CNF Conformance all Container Chaos" do
  before_all do
    `./cnf-conformance setup`
    $?.success?.should be_true
  end

  after_all do
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
  end

  it "'all' should run the whole test suite", tags: "happy-path" do
    `./cnf-conformance samples_cleanup`
    response_s = `./cnf-conformance all ~platform ~compatibilty ~statelessness ~security ~scalability ~configuration_lifecycle ~observability ~installability ~hardware_affinity ~microservice ~chaos_network_loss cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-conformance.yml verbose`
    LOGGING.info response_s
    (/Final workload score:/ =~ response_s).should_not be_nil
    (/Final score:/ =~ response_s).should_not be_nil
    (all_result_test_names(CNFManager.final_cnf_results_yml)).should eq([  "chaos_cpu_hog", "chaos_container_kill"])
    $?.success?.should be_true
  end
end
