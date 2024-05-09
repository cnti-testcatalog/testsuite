require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "kubectl_client"
require "helm"
require "../../src/tasks/dockerd_setup.cr"
require "file_utils"
require "sam"

describe "Microservice" do
  before_all do
    Log.info { "Running testsuite setup" }
    result = ShellCmd.run_testsuite("setup")
    result = ShellCmd.run_testsuite("setup")
    process_result = result[:status].success?
    Log.info(&.emit("Testsuite setup process result", process_result: process_result))
    process_result.should be_true
  end

  it "'shared_database' should be skipped no MariaDB containers are found", tags: ["shared_database"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample_coredns/cnf-testsuite.yml")
      result = ShellCmd.run_testsuite("shared_database")
      result[:status].success?.should be_true
      (/(N\/A).*(No MariaDB containers were found)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_coredns/cnf-testsuite.yml")
      result[:status].success?.should be_true
    end
  end

  it "'shared_database' should pass if no database is used by two microservices", tags: ["shared_database"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample-statefulset-cnf/cnf-testsuite.yml")
      result = ShellCmd.run_testsuite("shared_database")
      result[:status].success?.should be_true
      (/(PASSED).*(No shared database found)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample-statefulset-cnf/cnf-testsuite.yml")
      result[:status].success?.should be_true
    end
  end

  it "'shared_database' should pass if one service connects to a database but other non-service connections are made to the database", tags: ["shared_database"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample-multi-db-connections-exempt/cnf-testsuite.yml")
      result = ShellCmd.run_testsuite("shared_database")
      result[:status].success?.should be_true
      (/(PASSED).*(No shared database found)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample-multi-db-connections-exempt/cnf-testsuite.yml")
      result[:status].success?.should be_true
    end
  end

  it "'shared_database' should fail if two services on the cluster connect to the same database", tags: ["shared_database2"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/ndn-multi-db-connections-fail/cnf-testsuite.yml")
      result = ShellCmd.run_testsuite("shared_database")
      result[:status].success?.should be_true
      (/(FAILED).*(Found a shared database)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/ndn-multi-db-connections-fail/cnf-testsuite.yml")
      result[:status].success?.should be_true
      KubectlClient::Delete.command("pvc data-test-mariadb-0 -n wordpress")
    end
  end

  it "'shared_database' should pass if two services on the cluster connect to the same database but they are not in the helm chart of the cnf", tags: ["shared_database"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample_coredns")
      Helm.install("multi-db sample-cnfs/ndn-multi-db-connections-fail/wordpress/")
      KubectlClient::Get.resource_wait_for_install(kind: "Deployment", resource_name: "multi-db-wordpress", wait_count: 180, namespace: "default")
      KubectlClient::Get.resource_wait_for_install(kind: "Deployment", resource_name: "multi-db-wordpress2", wait_count: 180, namespace: "default")
      # todo kubctl appy of all resourcesin ndn-multi-db-connections-fail
      # todo cnf_setup of coredns
      # todo run shared_database (should pass)
      # todo kubectl delete on ndn resourcws
      # toto cnf_cleanup on coredns
      result = ShellCmd.run_testsuite("shared_database")
      result[:status].success?.should be_true
      (/(PASSED).*(No shared database found)/ =~ result[:output]).should_not be_nil
    ensure
      Helm.delete("multi-db")
      KubectlClient::Delete.command("pvc data-multi-db-mariadb-0")
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/ndn-multi-db-connections-fail/cnf-testsuite.yml")
      result[:status].success?.should be_true
    end
  end

  it "'single_process_type' should pass if the containers in the cnf have only one process type", tags: ["process_check"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample_coredns")
      result = ShellCmd.run_testsuite("single_process_type verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(Only one process type used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_coredns")
      result[:status].success?.should be_true
    end
  end

  it "'single_process_type' should fail if the containers in the cnf have more than one process type", tags: ["process_check"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/k8s-multiple-processes")
      result = ShellCmd.run_testsuite("single_process_type verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(More than one process type used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/k8s-multiple-processes")
      result[:status].success?.should be_true
    end
  end

  it "'single_process_type' should fail if the containers in the cnf have more than one process type and in a pod", tags: ["process_check"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample-multiple-processes")
      result = ShellCmd.run_testsuite("single_process_type verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(More than one process type used)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample-multiple-processes")
      result[:status].success?.should be_true
    end
  end

  it "'reasonable_startup_time' should pass if the cnf has a reasonable startup time(helm_directory)", tags: ["reasonable_startup_time"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample_coredns") 
      result = ShellCmd.run_testsuite("reasonable_startup_time verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(CNF had a reasonable startup time)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_coredns")
      result[:status].success?.should be_true
    end
  end

  it "'reasonable_startup_time' should fail if the cnf doesn't has a reasonable startup time(helm_directory)", tags: ["reasonable_startup_time"] do
    result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample_envoy_slow_startup/cnf-testsuite.yml force=true")
    begin
      result = ShellCmd.run_testsuite("reasonable_startup_time verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(CNF had a startup time of)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample_envoy_slow_startup/cnf-testsuite.yml force=true")
      result[:status].success?.should be_true
    end
  end

  it "'reasonable_image_size' should pass if image is smaller than 5gb, when using a protected image", tags: ["reasonable_image_size"]  do
    if ENV["PROTECTED_DOCKERHUB_USERNAME"]? && ENV["PROTECTED_DOCKERHUB_PASSWORD"]? && ENV["PROTECTED_DOCKERHUB_EMAIL"]? && ENV["PROTECTED_IMAGE_REPO"]
         cnf="./sample-cnfs/sample_coredns_protected"
       else
         cnf="./sample-cnfs/sample-coredns-cnf"
    end
    result = ShellCmd.run_testsuite("cnf_setup cnf-path=#{cnf}")
    result = ShellCmd.run_testsuite("reasonable_image_size verbose")
    result[:status].success?.should be_true
    (/Image size is good/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=#{cnf}")
  end

  it "'reasonable_image_size' should fail if image is larger than 5gb", tags: ["reasonable_image_size"] do
    result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/ndn-reasonable-image-size wait_count=0")
    result = ShellCmd.run_testsuite("reasonable_image_size verbose")
    result[:status].success?.should be_true
    (/Image size too large/ =~ result[:output]).should_not be_nil
  end

  it "'specialized_init_system' should fail if pods do not use specialized init systems", tags: ["specialized_init_system"] do
    result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/sample-coredns-cnf")
    result = ShellCmd.run_testsuite("specialized_init_system")
    result[:status].success?.should be_true
    (/Containers do not use specialized init systems/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample-coredns-cnf force=true")
  end

  it "'specialized_init_system' should pass if pods use specialized init systems", tags: ["specialized_init_system"] do
    result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/sample-init-systems")
    result = ShellCmd.run_testsuite("specialized_init_system")
    result[:status].success?.should be_true
    (/Containers use specialized init systems/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample-init-systems force=true")
  end

  it "'service_discovery' should pass if any containers in the cnf are exposed as a service", tags: ["service_discovery"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=sample-cnfs/sample_coredns")
      result = ShellCmd.run_testsuite("service_discovery verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(Some containers exposed as a service)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=sample-cnfs/sample_coredns")
      result[:status].success?.should be_true
    end
  end

  it "'service_discovery' should fail if no containers in the cnf are exposed as a service", tags: ["service_discovery"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/sample-ndn-privileged")
      result = ShellCmd.run_testsuite("service_discovery verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(No containers exposed as a service)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample-ndn-privileged")
      result[:status].success?.should be_true
    end
  end

  it "'sig_term_handled' should pass if SIGTERM are handeled by child processes", tags: ["sig_term"]  do
    begin
      #todo 1. Watch for signals for the containers pid one process, and the tree of all child processes ity manages
      #todo 2. Kill PID one / Uninstall the CNF
      #todo 3. Collect all signals sent, if SIGKILL is captured, application fails test because it doesn't exit child processes cleanly
      #todo 3. Collect all signals sent, if SIGTERM is captured, application pass test because it  exits child processes cleanly
      #todo 4. Make sure that threads are not counted as new processes.  A thread does not get a signal (sigterm or sigkill)
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/sample_good_signal_handling/")
      result = ShellCmd.run_testsuite("sig_term_handled verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(Sig Term handled)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample_good_signal_handling/")
      result[:status].success?.should be_true
    end
  end

  it "'sig_term_handled' should fail if SIGTERM isn't handled by child processes", tags: ["sig_term"]  do
    begin
      #todo 1. Watch for signals for the containers pid one process, and the tree of all child processes ity manages
      #todo 2. Kill PID one / Uninstall the CNF
      #todo 3. Collect all signals sent, if SIGKILL is captured, application fails test because it doesn't exit child processes cleanly
      #todo 3. Collect all signals sent, if SIGTERM is captured, application pass test because it  exits child processes cleanly
      #todo 4. Make sure that threads are not counted as new processes.  A thread does not get a signal (sigterm or sigkill)
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/sample_bad_signal_handling/")
      result = ShellCmd.run_testsuite("sig_term_handled verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(Sig Term not handled)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample_bad_signal_handling/")
      result[:status].success?.should be_true
    end
  end

  it "'sig_term_handled' should pass if SIGTERM is passed through to child processes by a supervisor (tini)", tags: ["sig_term"]  do
    begin
      #todo 1. Watch for signals for the containers pid one process, and the tree of all child processes ity manages
      #todo 2. Kill PID one / Uninstall the CNF
      #todo 3. Collect all signals sent, if SIGKILL is captured, application fails test because it doesn't exit child processes cleanly
      #todo 3. Collect all signals sent, if SIGTERM is captured, application pass test because it  exits child processes cleanly
      #todo 4. Make sure that threads are not counted as new processes.  A thread does not get a signal (sigterm or sigkill)
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/sample_good_signal_handling_tini/")

      # Workaround to wait using kubectl because Jenkins pod takes a LONG time to start.
      result = ShellCmd.run("kubectl wait --for=condition=ready=True pod/jenkins-0 -n cnfspace --timeout=500s", force_output: true)

      result = ShellCmd.run_testsuite("sig_term_handled verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(Sig Term handled)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample_good_signal_handling_tini/")
      result[:status].success?.should be_true
    end
  end

  it "'zombie_handled' should pass if a zombie is succesfully reaped by PID 1", tags: ["zombie"]  do
    begin

      result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/sample_good_zombie_handling/")
      result = ShellCmd.run_testsuite("zombie_handled verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(Zombie handled)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample_good_zombie_handling/")
      result[:status].success?.should be_true
    end
  end
  it "'zombie_handled' should failed if a zombie is not succesfully reaped by PID 1", tags: ["zombie"]  do
    begin

      result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/sample-bad-zombie/")
      result = ShellCmd.run_testsuite("zombie_handled verbose")
      result[:status].success?.should be_true
      (/(FAILED).*(Zombie not handled)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample-bad-zombie/")
      result[:status].success?.should be_true
    end
  end
end

