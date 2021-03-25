require "../spec_helper"
require "../../src/tasks/utils/utils.cr"
require "colorize"

describe CnfConformance do
  before_all do
    `./cnf-conformance setup`
    $?.success?.should be_true
  end

  after_all do
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
  end

  it "'all' should run the workloads test suite", tags: ["conformance-all"] do
    `./cnf-conformance samples_cleanup`
    # the workload resilience tests are run in the chaos specs
    # the ommisions (i.e. ~resilience) are done for performance reasons for the spec suite
    # response_s = `./cnf-conformance all ~platform ~resilience cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-conformance.yml verbose`
    response_s = `./cnf-conformance all ~disk_fill ~pod_network_latency ~chaos_network_loss ~chaos_cpu_hog ~chaos_container_kill ~platform ~ip_addresses ~liveness ~readiness ~rolling_update ~rolling_downgrade ~rolling_version_change ~nodeport_not_used ~hardcoded_ip_addresses_in_k8s_runtime_configuration ~rollback ~secrets_used ~immutable_configmap ~reasonable_startup_time ~reasonable_image_size "cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-conformance.yml" verbose`
    LOGGING.info response_s
    (/Lint Passed/ =~ response_s).should_not be_nil
    (/PASSED: Replicas increased to 3/ =~ response_s).should_not be_nil
    (/PASSED: Replicas decreased to 1/ =~ response_s).should_not be_nil
    (/PASSED: Published Helm Chart Found/ =~ response_s).should_not be_nil
    (/Final workload score:/ =~ response_s).should_not be_nil
    (/Final score:/ =~ response_s).should_not be_nil
    (CNFManager::Points.all_result_test_names(CNFManager::Points.final_cnf_results_yml).sort).should eq(["volume_hostpath_not_found", "privileged", "increase_capacity", "decrease_capacity", "install_script_helm", "helm_chart_valid", "helm_chart_published"].sort)
    (/^.*\.cr:[0-9].*/ =~ response_s).should be_nil
    $?.success?.should be_true
  end
end
