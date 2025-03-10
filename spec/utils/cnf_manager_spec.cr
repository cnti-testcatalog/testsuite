# coding: utf-8
require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/helmenv_setup.cr"
require "../../src/tasks/utils/utils.cr"
require "kubectl_client"
require "file_utils"
require "sam"

describe "SampleUtils" do
  before_all do
    result = ShellCmd.run_testsuite("helm_local_install")
    result[:status].success?.should be_true
    # Ensure a results file is present to test different scenarios
    CNFManager::Points::Results.ensure_results_file!
  end

  it "'points_yml' should parse and return the points yaml file", tags: ["points"]  do
    (CNFManager::Points.points_yml.find {|x| x["name"] =="liveness"}).should be_truthy 
  end

  it  "'task_points' should return the amount of points for a passing test", tags: ["points"] do
    # default
    (CNFManager::Points.task_points("liveness")).should eq(100)
    # assigned
    (CNFManager::Points.task_points("increase_capacity")).should eq(5)
  end

  it  "'task_points(, false)' should return the amount of points for a failing test", tags: ["points"]  do
    # default
    (CNFManager::Points.task_points("liveness", false)).should eq(0)
    # assigned
    (CNFManager::Points.task_points("increase_decrease_capacity", false)).should eq(0)
  end

  it  "'task_points(, skipped)' should return the amount of points for a skipped test", tags: ["points"]  do
    # default
    (CNFManager::Points.task_points("liveness", CNFManager::ResultStatus::Skipped)).should eq(0)
  end

  it "'upsert_task' insert task in the results file", tags: ["tasks"]  do
    CNFManager::Points.clean_results_yml
    CNFManager::Points.upsert_task("liveness", PASSED, CNFManager::Points.task_points("liveness"), Time.utc)
    yaml = File.open("#{CNFManager::Points::Results.file}") do |file|
      YAML.parse(file)
    end
    (yaml["items"].as_a.find {|x| x["name"] == "liveness" && x["points"] == CNFManager::Points.task_points("liveness")}).should be_truthy
  end

  it "'upsert_task' should find and update an existing task in the file", tags: ["tasks"]  do
    CNFManager::Points.clean_results_yml
    CNFManager::Points.upsert_task("liveness", PASSED, CNFManager::Points.task_points("liveness"), Time.utc)
    CNFManager::Points.upsert_task("liveness", PASSED, CNFManager::Points.task_points("liveness"), Time.utc)
    yaml = File.open("#{CNFManager::Points::Results.file}") do |file|
      YAML.parse(file)
    end
    (yaml["items"].as_a.find {|x| x["name"] == "liveness" && x["points"] == CNFManager::Points.task_points("liveness")}).should be_truthy
    (CNFManager::Points.total_points).should eq(100)
  end

  it "'CNFManager::Points.total_points' should sum the total amount of points in the results", tags: ["points"] do
    CNFManager::Points.clean_results_yml
    CNFManager::Points.upsert_task("liveness", PASSED, CNFManager::Points.task_points("liveness"), Time.utc)
    (CNFManager::Points.total_points).should eq(100)
  end

  it "'CNFManager::Points.total_max_points' should not include na in the total potential points", tags: ["points"] do
    CNFManager::Points.clean_results_yml
    upsert_passed_task("liveness", "✔️  PASSED: CNF had a reasonable startup time ", Time.utc)
    resp1 = CNFManager::Points.total_max_points
    upsert_na_task("readiness", "✔️  NA", Time.utc)
    resp2 = CNFManager::Points.total_max_points
   
    Log.info { "readiness points: #{CNFManager::Points.task_points("readiness").not_nil!.to_i}" }
    (resp2).should eq((resp1 - CNFManager::Points.task_points("readiness").not_nil!.to_i))
  end

  it "'CNFManager::Points.tasks_by_tag' should return the tasks assigned to a tag", tags: ["points"] do
    CNFManager::Points.clean_results_yml
    tags = [
      "alpha_k8s_apis", "hardcoded_ip_addresses_in_k8s_runtime_configuration", "hostport_not_used",
      "immutable_configmap", "ip_addresses", "nodeport_not_used", "secrets_used", "versioned_tag",
      "require_labels", "default_namespace", "latest_tag", "operator_installed"
    ]
    (CNFManager::Points.tasks_by_tag("configuration")).sort.should eq(tags.sort)
    (CNFManager::Points.tasks_by_tag("does-not-exist")).should eq([] of YAML::Any) 
  end

  it "'CNFManager::Points.tasks_by_tag' should only return the tasks that are within their category ", tags: ["points"] do
    CNFManager::Points.clean_results_yml
    (CNFManager::Points.tasks_by_tag("resilience").find{|x| x=="worker_reboot_recovery"}).should be_nil
  end

  it "'CNFManager::Points.tags_by_task' should return tags for a task ", tags: ["points"] do
    CNFManager::Points.clean_results_yml
    (CNFManager::Points.tags_by_task("latest_tag").find{|x| x=="cert"}).should_not be_nil
  end

  it "'CNFManager::Points.all_task_test_names' should return all tasks names", tags: ["points"] do
    CNFManager::Points.clean_results_yml
		tags = ["alpha_k8s_apis", "application_credentials", "cni_compatible", "container_sock_mounts", "database_persistence", "default_namespace", "disk_fill", "elastic_volumes", "external_ips", "hardcoded_ip_addresses_in_k8s_runtime_configuration", "helm_chart_published", "helm_chart_valid", "helm_deploy", "host_network", "host_pid_ipc_privileges", "hostpath_mounts", "hostport_not_used", "immutable_configmap", "immutable_file_systems", "increase_decrease_capacity", "ingress_egress_blocked", "insecure_capabilities", "ip_addresses", "latest_tag", "linux_hardening", "liveness", "log_output", "no_local_volume_configuration", "node_drain", "nodeport_not_used", "non_root_containers", "open_metrics", "operator_installed", "oran_e2_connection", "pod_delete", "pod_dns_error", "pod_io_stress", "pod_memory_hog", "pod_network_corruption", "pod_network_duplication", "pod_network_latency", "privilege_escalation", "privileged_containers", "prometheus_traffic", "readiness", "reasonable_image_size", "reasonable_startup_time", "require_labels", "cpu_limits", "memory_limits", "rollback", "rolling_downgrade", "rolling_update", "rolling_version_change", "routed_logs", "secrets_used", "selinux_options", "service_account_mapping", "service_discovery", "shared_database", "sig_term_handled", "single_process_type", "smf_upf_heartbeat", "specialized_init_system", "suci_enabled", "symlink_file_system", "sysctls", "tracing", "versioned_tag", "zombie_handled"]
    (CNFManager::Points.all_task_test_names()).sort.should eq(tags.sort)
  end

  it "'CNFManager::Points.all_result_test_names' should return the tasks assigned to a tag", tags: ["points"] do
    CNFManager::Points.clean_results_yml
    CNFManager::Points.upsert_task("liveness", PASSED, CNFManager::Points.task_points("liveness"), Time.utc)
    (CNFManager::Points.all_result_test_names(CNFManager::Points::Results.file)).should eq(["liveness"])
  end
  it "'CNFManager::Points.results_by_tag' should return a list of results by tag", tags: ["points"] do
    CNFManager::Points.clean_results_yml
    CNFManager::Points.upsert_task("liveness", PASSED, CNFManager::Points.task_points("liveness"), Time.utc)
    (CNFManager::Points.results_by_tag("resilience")).should eq([{"name" => "liveness", "status" => "passed", "type" => "essential", "points" => 100}])
    (CNFManager::Points.results_by_tag("does-not-exist")).should eq([] of YAML::Any) 
  end


  it "'#CNFManager::Points::Results.file' should return the name of the current yaml file", tags: ["points"]  do
    CNFManager::Points.clean_results_yml
    yaml = File.open("#{CNFManager::Points::Results.file}") do |file|
      YAML.parse(file)
    end
    (yaml["name"]).should eq("cnf testsuite")
    (yaml["exit_code"]).should eq(0) 
  end

  it "'CNFManager::Points.final_cnf_results_yml. should return the latest time stamped results file", tags: ["points"]  do
    (CNFManager::Points.final_cnf_results_yml).should contain("cnf-testsuite-results")
  end

  it "'validate_config' should pass, when a cnf has a valid config file yml", tags: ["validate_config"]  do
    result = ShellCmd.run_testsuite("validate_config cnf-config=spec/fixtures/cnf-testsuite-v2-example.yml")
    result[:status].success?.should be_true
    (/Successfully validated CNF config/ =~ result[:output]).should_not be_nil
  end

  it "'validate_config' should pass, for all sample-cnfs", tags: ["validate_config"]  do
    get_dirs = Dir.entries("sample-cnfs")
    dir_list = get_dirs - [".", ".."]
    dir_list.each do |dir|
      testsuite_yml = "sample-cnfs/#{dir}/cnf-testsuite.yml"
      result = ShellCmd.run_testsuite("validate_config cnf-config=#{testsuite_yml}")
      unless result[:status].success?
        Log.info {"Could not validate config: #{testsuite_yml}"}
      end
      (/Successfully validated CNF config/ =~ result[:output]).should_not be_nil
    end
  end

  it "'validate_config' should pass, for all example-cnfs", tags: ["validate_config"]  do
    get_dirs = Dir.entries("example-cnfs")
    dir_list = get_dirs - [".", ".."]
    dir_list.each do |dir|
      testsuite_yml = "example-cnfs/#{dir}/cnf-testsuite.yml"
      result = ShellCmd.run_testsuite("validate_config cnf-config=#{testsuite_yml}")
      unless result[:status].success?
        Log.info {"Could not validate config: #{testsuite_yml}"}
      end
      (/Successfully validated CNF config/ =~ result[:output]).should_not be_nil
    end
  end


  it "'CNFInstall::Config.parse_cnf_config_from_file' should return a populated CNFInstall::Config::Config", tags: ["cnf-config"]  do
    config = CNFInstall::Config.parse_cnf_config_from_file("spec/fixtures/cnf-testsuite.yml")    
    (config.deployments.helm_charts[0].name).should eq("coredns")
  end

  it "'CNFManager.workload_resource_test' should accept an args and cnf-config argument, populate a deployment, container, and intialized argument, and then apply a test to a cnf", tags: ["cnf-config"]  do
    begin
      args = Sam::Args.new()
      config_path = "./sample-cnfs/sample-generic-cnf/cnf-testsuite.yml"
      ShellCmd.cnf_install("cnf-config=#{config_path}")
      config = CNFInstall::Config.parse_cnf_config_from_file(config_path)    
      task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
        test_passed = true
		  		begin
		  			Log.trace { container.as_h["name"].as_s }
		  			container.as_h["livenessProbe"].as_h 
		  		rescue ex
		  			Log.error { ex.message }
		  			test_passed = false 
            puts "No livenessProbe found for resource: #{resource} and container: #{container.as_h["name"].as_s}".colorize(:red)
		  		end
        test_passed 
      end
      (task_response).should be_true 
    ensure
      ShellCmd.cnf_uninstall()
    end
  end

  it "Helm_values should be used during the installation of a cnf", tags: ["cnf-config"]  do
    begin
      # fails because doesn't have a service
      ShellCmd.cnf_install("cnf-path=./sample-cnfs/sample_coredns_values")
      deployment_containers = KubectlClient::Get.resource_containers("deployment", "coredns-coredns", "cnf-default")
      image_tags = KubectlClient::Get.container_image_tags(deployment_containers) 
      Log.info { "image_tags: #{image_tags}" }
      (/1.6.9/ =~ image_tags[0][:tag]).should_not be_nil
    ensure
      result = ShellCmd.cnf_uninstall()
    end
  end
end
