require "../spec_helper"
require "../../src/tasks/utils/utils.cr"
require "colorize"

describe CnfTestSuite do
  before_all do
    `./cnf-testsuite setup`
    $?.success?.should be_true
  end

  after_all do
    `./cnf-testsuite samples_cleanup`
    $?.success?.should be_true
  end

  it "'all' should run the workloads test suite", tags: ["testsuite-all"] do
    `./cnf-testsuite samples_cleanup`
    # the workload resilience tests are run in the chaos specs
    # the ommisions (i.e. ~resilience) are done for performance reasons for the spec suite
    # response_s = `./cnf-testsuite all ~platform ~resilience cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml verbose`
    response_s = `./cnf-testsuite all ~disk_fill ~pod_delete ~pod_network_latency ~pod_io_stress ~pod_network_duplication ~pod_network_corruption ~pod_memory_hog ~node_drain ~pod_dns_error ~chaos_network_loss ~chaos_cpu_hog ~chaos_container_kill ~platform ~ip_addresses ~liveness ~readiness ~rolling_update ~rolling_downgrade ~rolling_version_change ~nodeport_not_used ~hostport_not_used ~hardcoded_ip_addresses_in_k8s_runtime_configuration ~rollback ~secrets_used ~immutable_configmap ~reasonable_startup_time ~reasonable_image_size "cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml" verbose`
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

  it "'workload' should fail with an exit code when a required cnf fails", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_privileged_cnf/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite workload ~automatic_cnf_install ~ensure_cnf_installed ~configuration_file_setup ~compatibility ~state ~scalability ~configuration_lifecycle ~observability ~installability ~hardware_and_scheduling ~microservice ~resilience ~non_root_user`
      LOGGING.info response_s
      $?.success?.should be_false
      (/Found.*privileged containers.*coredns/ =~ response_s).should_not be_nil
      response_s = `./cnf-testsuite privileged strict`
      $?.success?.should be_false
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_privileged_cnf/cnf-testsuite.yml`
    end
  end

  it "a task should fail with an exit code of 2 when there is an exception", tags: ["security"] do
    begin
      response_s = `./cnf-testsuite divide_by_zero strict`
      LOGGING.info response_s
      ($?.exit_code == 2).should be_true
    end
  end
end
