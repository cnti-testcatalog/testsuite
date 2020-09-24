# coding: utf-8
desc "Platform Tests"
task "platform", ["helmenv_setup", "k8s_conformance", "platform:obervability", "platform:resilience", "platform:hardware_and_scheduling"]  do |_, args|
  VERBOSE_LOGGING.info "platform" if check_verbose(args)
  stdout_score("platform")
end

desc "Does the platform pass the K8s conformance tests?"
task "k8s_conformance" do |_, args|
  VERBOSE_LOGGING.info "k8s_conformance" if check_verbose(args)
  begin
    #TODO enable full test with production mode
    #sonobuoy = `sonobuoy run --wait` if PRODUCTION_MODE and not in test_mode
    current_dir = FileUtils.pwd 
    VERBOSE_LOGGING.debug current_dir if check_verbose(args)
    sonobuoy = "#{current_dir}/#{TOOLS_DIR}/sonobuoy/sonobuoy"

    # Clean up old results
    delete = `#{sonobuoy} delete --all --wait`
    VERBOSE_LOGGING.info delete if check_verbose(args)

    # Run the tests
    #TODO when in test mode --mode quick, prod mode no quick
    testrun = ""
    VERBOSE_LOGGING.info ENV["CRYSTAL_ENV"]? if check_verbose(args)
    if ENV["CRYSTAL_ENV"]? == "TEST"
      LOGGING.info("Running Sonobuoy using Quick Mode")
      testrun = `#{sonobuoy} run --wait --mode quick`
    else
      LOGGING.info("Running Sonobuoy Conformance")
      testrun = `#{sonobuoy} run --wait`
    end
    VERBOSE_LOGGING.info testrun if check_verbose(args)

    results = `results=$(#{sonobuoy} retrieve); #{sonobuoy} results $results` 
    VERBOSE_LOGGING.info results if check_verbose(args)

    # Grab the failed line from the results
    failed_count = ((results.match(/Failed: (.*)/)).try &.[1]) 
    if failed_count.to_s.to_i > 0 
      upsert_failed_task("k8s_conformance", "✖️  FAILURE: K8s conformance test has #{failed_count} failure(s)!")
    else
      upsert_passed_task("k8s_conformance", "✔️  PASSED: K8s conformance test has no failures")
    end
  rescue ex
    LOGGING.error ex.message
    ex.backtrace.each do |x|
      LOGGING.error x
    end
  ensure
    remove_tar = `rm *sonobuoy*.tar.gz`
    VERBOSE_LOGGING.debug remove_tar if check_verbose(args)
  end
end
