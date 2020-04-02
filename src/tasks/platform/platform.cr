desc "Platform Tests"
task "platform", ["k8s_conformance"]  do |_, args|
end

desc "Does the platform pass the K8s conformance tests?"
task "k8s_conformance" do |_, args|
  begin
    #TODO enable full test with production mode
    #sonobuoy = `sonobuoy run --wait` if PRODUCTION_MODE and not in test_mode
    current_dir = FileUtils.pwd 
    puts current_dir if check_verbose(args)
    sonobuoy = "#{current_dir}/#{TOOLS_DIR}/sonobuoy/sonobuoy"

    # Clean up old results
    delete = `#{sonobuoy} delete --wait`
    puts delete if check_verbose(args)

    # Run the tests
    #TODO when in test mode --mode quick, prod mode no quick
    testrun = ""
    puts ENV["CRYSTAL_ENV"]? if check_verbose(args)
    if ENV["CRYSTAL_ENV"]? == "TEST"
      testrun = `#{sonobuoy} run --wait --mode quick`
    else
      testrun = `#{sonobuoy} run --wait`
    end
    puts testrun if check_verbose(args)

    results = `results=$(#{sonobuoy} retrieve); #{sonobuoy} results $results` 
    puts results if check_verbose(args)

    # Grab the failed line from the results
    failed_count = ((results.match(/Failed: (.*)/)).try &.[1]) 
    if failed_count.to_s.to_i > 0 
      puts "FAILURE: K8s conformance test has #{failed_count} failure(s)!".colorize(:red)
    else
      puts "PASSED: K8s conformance test has no failures".colorize(:green)
    end
  rescue ex
    puts ex.message
    ex.backtrace.each do |x|
      puts x
    end
  ensure
    remove_tar = `rm *sonobuoy*.tar.gz`
    puts remove_tar if check_verbose(args)
  end
end
