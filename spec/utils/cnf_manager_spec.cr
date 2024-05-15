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
    result = ShellCmd.run_testsuite("cleanup")
    result[:status].success?.should be_true

    # Ensure a results file is present to test different scenarios
    CNFManager::Points::Results.ensure_results_file!
  end

  after_each do
    result = ShellCmd.run_testsuite("cleanup")
    result[:status].success?.should be_true
  end

  it "'images_from_config_src' should return a list of containers for a cnf", tags: ["cnf-setup"]  do
    (CNFManager::GenerateConfig.images_from_config_src("stable/coredns").find {|x| x[:image_name] =="coredns/coredns" && 
                                                                               x[:container_name] =="coredns"}).should be_truthy 
  end

  it "'cnf_setup' should pass with a minimal cnf-testsuite.yml", tags: ["cnf-setup"] do
    result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/sample-minimal-cnf/ wait_count=0")
    result[:status].success?.should be_true
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample-minimal-cnf/ force=true")
  end

  it "'cnf_setup' should support cnf-config as an alias for cnf-path", tags: ["cnf-setup"] do
    result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample-minimal-cnf/ wait_count=0")
    result[:status].success?.should be_true
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample-minimal-cnf/ force=true")
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
    (CNFManager::Points.tasks_by_tag("resilience").
     find{|x| x=="worker_reboot_recovery"}).should be_nil
  end

  it "'CNFManager::Points.tags_by_task' should return tags for a task ", tags: ["points"] do
    CNFManager::Points.clean_results_yml
    (CNFManager::Points.tags_by_task("latest_tag").
     find{|x| x=="cert"}).should_not be_nil
  end

  it "'CNFManager::Points.all_task_test_names' should return all tasks names", tags: ["points"] do
    CNFManager::Points.clean_results_yml
		tags = ["alpha_k8s_apis", "application_credentials", "cni_compatible", "container_sock_mounts", "database_persistence", "default_namespace", "disk_fill", "elastic_volumes", "external_ips", "hardcoded_ip_addresses_in_k8s_runtime_configuration", "helm_chart_published", "helm_chart_valid", "helm_deploy", "host_network", "host_pid_ipc_privileges", "hostpath_mounts", "hostport_not_used", "immutable_configmap", "immutable_file_systems", "increase_decrease_capacity", "ingress_egress_blocked", "insecure_capabilities", "ip_addresses", "latest_tag", "linux_hardening", "liveness", "log_output", "no_local_volume_configuration", "node_drain", "nodeport_not_used", "non_root_containers", "open_metrics", "operator_installed", "oran_e2_connection", "pod_delete", "pod_dns_error", "pod_io_stress", "pod_memory_hog", "pod_network_corruption", "pod_network_duplication", "pod_network_latency", "privilege_escalation", "privileged", "privileged_containers", "prometheus_traffic", "readiness", "reasonable_image_size", "reasonable_startup_time", "require_labels", "cpu_limits", "memory_limits", "rollback", "rolling_downgrade", "rolling_update", "rolling_version_change", "routed_logs", "secrets_used", "selinux_options", "service_account_mapping", "service_discovery", "shared_database", "sig_term_handled", "single_process_type", "smf_upf_heartbeat", "specialized_init_system", "suci_enabled", "symlink_file_system", "sysctls", "tracing", "versioned_tag", "zombie_handled"]
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


  it "'CNFManager.sample_setup_cli_args(args) and CNFManager.sample_setup(cli_args)' should set up a sample cnf", tags: ["cnf-setup"]  do
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-testsuite.yml", "verbose", "wait_count=180"])
    cli_hash = CNFManager.sample_setup_cli_args(args)
    CNFManager.sample_setup(cli_hash)
    config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(cli_hash[:config_file]))    
    release_name = config.cnf_config[:release_name]

    (Dir.exists? "cnfs/#{release_name}").should be_true
    (File.exists?("cnfs/#{release_name}/cnf-testsuite.yml")).should be_true
    (File.exists?("cnfs/#{release_name}/exported_chart/Chart.yaml")).should be_true
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (Dir.exists? "cnfs/#{release_name}").should be_false
  end

  it "'CNFManager.sample_setup' should set up a sample cnf", tags: ["cnf-setup"]  do
    config_file = "sample-cnfs/sample-generic-cnf"
    args = Sam::Args.new(["cnf-config=./#{config_file}/cnf-testsuite.yml", "verbose", "wait_count=0"])
    cli_hash = CNFManager.sample_setup_cli_args(args)
    CNFManager.sample_setup(cli_hash)
    # check if directory exists
    config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file))    
    release_name = config.cnf_config[:release_name]

    (Dir.exists? "cnfs/#{release_name}").should be_true
    (File.exists?("cnfs/#{release_name}/cnf-testsuite.yml")).should be_true
    (File.exists?("cnfs/#{release_name}/exported_chart/Chart.yaml")).should be_true
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (Dir.exists? "cnfs/#{release_name}").should be_false
  end

  it "'CNFManager.sample_setup_args' should set up a sample cnf from a argument", tags: ["cnf-setup"]  do
    config_file = "sample-cnfs/sample-generic-cnf"
    args = Sam::Args.new(["cnf-config=./#{config_file}/cnf-testsuite.yml", "verbose", "wait_count=0"])
    cli_hash = CNFManager.sample_setup_cli_args(args)
    CNFManager.sample_setup(cli_hash)
    # check if directory exists
    config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file))    
    release_name = config.cnf_config[:release_name]
    (Dir.exists? "cnfs/#{release_name}").should be_true
    (File.exists?("cnfs/#{release_name}/cnf-testsuite.yml")).should be_true
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (Dir.exists? "cnfs/#{release_name}").should be_false
  end

  it "'CNFManager.sample_setup_args' should set up a sample cnf from a config file", tags: ["cnf-setup"]  do
    config_file = "sample-cnfs/sample-generic-cnf"
    args = Sam::Args.new(["cnf-config=./#{config_file}/cnf-testsuite.yml", "verbose", "wait_count=0"])
    cli_hash = CNFManager.sample_setup_cli_args(args)
    CNFManager.sample_setup(cli_hash)
    # check if directory exists
    config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file))    
    release_name = config.cnf_config[:release_name]
    (Dir.exists? "sample-cnfs/sample-generic-cnf").should be_true
    (File.exists?("cnfs/#{release_name}/cnf-testsuite.yml")).should be_true
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (Dir.exists? "cnfs/#{release_name}").should be_false
  end

  it "'CNFManager.sample_cleanup' should clean up a sample cnf from a argument", tags: ["cnf-setup"]  do
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-testsuite.yml", "verbose", "wait_count=0"])
    cli_hash = CNFManager.sample_setup_cli_args(args)
    CNFManager.sample_setup(cli_hash)
    cleanup = CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
    (cleanup).should be_true 
    (Dir.exists? "cnfs/coredns").should be_false
    (File.exists?("cnfs/coredns/cnf-testsuite.yml")).should be_false
    (File.exists?("cnfs/coredns/helm_chart/Chart.yaml")).should be_false
  end

  it "'CNFManager.sample_setup_args' should be able to deploy using a helm_directory", tags: ["cnf-setup"]  do
    config_file = "sample-cnfs/sample_privileged_cnf"
    args = Sam::Args.new(["cnf-config=./#{config_file}/cnf-testsuite.yml", "verbose", "wait_count=0"])
    cli_hash = CNFManager.sample_setup_cli_args(args)
    CNFManager.sample_setup(cli_hash)
    config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file))    
    release_name = config.cnf_config[:release_name]
    (Dir.exists? "cnfs/#{release_name}").should be_true
    # should not clone
    (Dir.exists? "cnfs/#{release_name}/privileged-coredns").should be_false
    (File.exists? "cnfs/#{release_name}/cnf-testsuite.yml").should be_true
    (File.exists? "cnfs/#{release_name}/chart/Chart.yaml").should be_true
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample_privileged_cnf", verbose: true)
    (Dir.exists? "cnfs/#{release_name}").should be_false
  end

  it "'CNFManager.sample_setup_args and CNFManager.sample_cleanup' should be able to deploy and cleanup using a manifest_directory", tags: ["cnf-setup"]  do
    config_file = "sample-cnfs/k8s-non-helm"
    args = Sam::Args.new(["cnf-config=./#{config_file}/cnf-testsuite.yml", "verbose", "wait_count=0"])
    cli_hash = CNFManager.sample_setup_cli_args(args)
    Log.info { "Running Setup" }
    CNFManager.sample_setup(cli_hash)
    Log.info { "Parse Config" }
    config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file))    
    release_name = config.cnf_config[:release_name]
    (Dir.exists? "cnfs/#{release_name}").should be_true
    (Dir.exists? "cnfs/#{release_name}/manifests").should be_true
    (File.exists? "cnfs/#{release_name}/cnf-testsuite.yml").should be_true
    (KubectlClient::Get.pod_exists?("nginx-webapp")).should be_true
    CNFManager.sample_cleanup(config_file: "sample-cnfs/k8s-non-helm", installed_from_manifest: true, verbose: true)
    # TODO check for pod status = terminating
    (KubectlClient::Get.pod_exists?("nginx-webapp", check_ready: true)).should be_false
    (Dir.exists? "cnfs/#{release_name}").should be_false
  end

  it "'cnf_destination_dir' should return the full path of the potential destination cnf directory based on the deployment name", tags: "WIP" do
    args = Sam::Args.new
    CNFManager.cnf_destination_dir("spec/fixtures/cnf-testsuite.yml").should contain("/cnfs/coredns")
  end

  it "'CNFManager.cnf_config_list' should return a list of all of the config files from the cnf directory", tags: ["cnf-setup"]  do
    config_file = "sample-cnfs/sample-generic-cnf"
    args = Sam::Args.new(["cnf-config=./#{config_file}/cnf-testsuite.yml", "verbose", "wait_count=0"])
    cli_hash = CNFManager.sample_setup_cli_args(args)
    CNFManager.sample_setup(cli_hash)
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample_privileged_cnf/cnf-testsuite.yml", "verbose"])
    cli_hash = CNFManager.sample_setup_cli_args(args)
    CNFManager.sample_setup(cli_hash)
    config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file))    
    release_name = config.cnf_config[:release_name]
    CNFManager.cnf_config_list()[0].should contain("#{release_name}/#{CONFIG_FILE}")
  end

  it "'CNFManager.helm_repo_add' should add a helm repo if the helm repo is valid", tags: ["helm-repo"] do
    config_file = "sample-cnfs/sample-generic-cnf"
    args = Sam::Args.new(["cnf-config=./#{config_file}/cnf-testsuite.yml", "verbose", "wait_count=0"])
    cli_hash = CNFManager.sample_setup_cli_args(args)
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-testsuite.yml"])
    CNFManager.helm_repo_add(args: args).should eq(true)
  end

  it "'CNFManager.helm_repo_add' should return false if the helm repo is invalid", tags: ["helm-repo"]  do
    CNFManager.helm_repo_add("invalid", "invalid").should eq(false)
  end

  it "'CNFManager.validate_cnf_testsuite_yml' (function) should pass, when a cnf has a valid config file yml", tags: ["validate_config"]  do
    args = Sam::Args.new(["cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml"])

    yml = CNFManager.parsed_config_file(CNFManager.ensure_cnf_testsuite_yml_path(args.named["cnf-config"].as(String)))
    Log.info { yml.inspect }
    ("#{yml.get("release_name").as_s?}").should eq("coredns")

    valid, command_output = CNFManager.validate_cnf_testsuite_yml(yml)

    (valid).should eq(true)
    (command_output).should eq (nil)
  end

  it "'CNFManager.validate_cnf_testsuite_yml' (command) should pass, when a cnf has a valid config file yml", tags: ["validate_config"]  do
    result = ShellCmd.run_testsuite("validate_config cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
    result[:status].success?.should be_true
    (/CNF configuration validated/ =~ result[:output]).should_not be_nil
  end


  it "'CNFManager.validate_cnf_testsuite_yml' (function) should warn, but be valid when a cnf config file yml has fields that are not a part of the validation type", tags: ["validate_config"]  do
    args = Sam::Args.new(["cnf-config=./spec/fixtures/cnf-testsuite-unmapped-keys-and-subkeys.yml"])

    yml = CNFManager.parsed_config_file(CNFManager.ensure_cnf_testsuite_yml_path(args.named["cnf-config"].as(String)))
    Log.info { yml.inspect }
    ("#{yml.get("release_name").as_s?}").should eq("coredns")

    status, warning_output = CNFManager.validate_cnf_testsuite_yml(yml)

    Log.warn { "WARNING: #{warning_output}" }

    (status).should eq(true)
    (warning_output).should_not be_nil
  end


  it "'CNFManager.validate_cnf_testsuite_yml' (command) should warn, but be valid when a cnf config file yml has fields that are not a part of the validation type", tags: ["validate_config"]  do
    result = ShellCmd.run_testsuite("validate_config cnf-config=spec/fixtures/cnf-testsuite-unmapped-keys-and-subkeys.yml")
    result[:status].success?.should be_true
    Log.debug { "validate_config resp: #{result[:output]}" }
    (/CNF configuration validated/ =~ result[:output]).should_not be_nil
  end


  it "'CNFManager.validate_cnf_testsuite_yml' (command) should pass, for all sample-cnfs", tags: ["validate_config"]  do

    get_dirs = Dir.entries("sample-cnfs")
    dir_list = get_dirs - [".", ".."]
    dir_list.each do |dir|
      testsuite_yml = "sample-cnfs/#{dir}/cnf-testsuite.yml"
      result = ShellCmd.run_testsuite("validate_config cnf-config=#{testsuite_yml}")
      (/CNF configuration validated/ =~ result[:output]).should_not be_nil
    end
  end

  it "'CNFManager.validate_cnf_testsuite_yml' (command) should pass, for all example-cnfs", tags: ["validate_config"]  do

    get_dirs = Dir.entries("example-cnfs")
    dir_list = get_dirs - [".", ".."]
    dir_list.each do |dir|
      testsuite_yml = "example-cnfs/#{dir}/cnf-testsuite.yml"
      result = ShellCmd.run_testsuite("validate_config cnf-config=#{testsuite_yml}")
      if (/Critical Error with CNF Configuration. Please review USAGE.md for steps to set up a valid CNF configuration file/ =~ result[:output])
        Log.info { "\n #{testsuite_yml}: #{result[:output]}" }
      end
      (/CNF configuration validated/ =~ result[:output]).should_not be_nil
    end
  end


  it "'CNFManager::Config#parse_config_yml' should return a populated CNFManager::Config.cnf_config", tags: ["cnf-config"]  do
    begin
      yaml = CNFManager::Config.parse_config_yml("spec/fixtures/cnf-testsuite.yml")    
    (yaml.cnf_config[:release_name]).should eq("coredns")
    ensure
    end
  end

  it "'CNFManager.workload_resource_test' should accept an args and cnf-config argument, populate a deployment, container, and intialized argument, and then apply a test to a cnf", tags: ["cnf-config"]  do
    args = Sam::Args.new(["cnf-config=./sample-cnfs/sample-generic-cnf/cnf-testsuite.yml"])
    cli_hash = CNFManager.sample_setup_cli_args(args, false)
    CNFManager.sample_setup(cli_hash) if cli_hash["config_file"]
    config = CNFManager::Config.parse_config_yml("./sample-cnfs/sample-generic-cnf/cnf-testsuite.yml")    
    task_response = CNFManager.workload_resource_test(args, config) do |resource, container, initialized|
      test_passed = true
				begin
					Log.for("verbose").debug { container.as_h["name"].as_s } if check_verbose(args)
					container.as_h["livenessProbe"].as_h 
				rescue ex
					Log.for("verbose").error { ex.message } if check_verbose(args)
					test_passed = false 
          puts "No livenessProbe found for resource: #{resource} and container: #{container.as_h["name"].as_s}".colorize(:red)
				end
      test_passed 
    end
    (task_response).should be_true 
    CNFManager.sample_cleanup(config_file: "sample-cnfs/sample-generic-cnf", verbose: true)
  end

  it "'CNFManager.exclusive_install_method_tags' should return false if install method tags are not exclusive", tags: ["cnf-config"]  do
    config = CNFManager.parsed_config_file("./spec/fixtures/cnf-testsuite-not-exclusive.yml")
    resp = CNFManager.exclusive_install_method_tags?(config)
    (resp).should be_false 
  end

  it "bonus tests should not be includded in the maximum points when a failure occurs", tags: ["cnf-config"]  do
    begin
      # fails because doesn't have a service
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/sample-ndn-privileged")
      result = ShellCmd.run_testsuite("cert_microservice")
      (/of 6 tests passed/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample-ndn-privileged")
    end
  end

  it "Helm_values should be used during the installation of a cnf", tags: ["cnf-config"]  do
    begin
      # fails because doesn't have a service
      result = ShellCmd.run_testsuite("cnf_setup cnf-path=./sample-cnfs/sample_coredns_values") 
      deployment_containers = KubectlClient::Get.deployment_containers("coredns-coredns")
      image_tags = KubectlClient::Get.container_image_tags(deployment_containers) 
      Log.info { "image_tags: #{image_tags}" }
      (/1.6.9/ =~ image_tags[0][:tag]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=./sample-cnfs/sample_coredns_values")
    end
  end

end
