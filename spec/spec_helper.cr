require "spec"
require "colorize"
require "../src/cnf_testsuite"
require "../src/tasks/utils/utils.cr"

ENV["CRYSTAL_ENV"] = "TEST" 


Log.info { "Building ./cnf-testsuite".colorize(:green) }
result = ShellCmd.run("crystal build --warnings none src/cnf-testsuite.cr")
if result[:status].success?
  Log.info { "Build Success!".colorize(:green) }
else
  Log.info { "crystal build failed!".colorize(:red) }
  raise "crystal build failed in spec_helper"
end

module ShellCmd
  def self.run_testsuite(testsuite_cmd, cmd_prefix="")
    cmd = "#{cmd_prefix} ./cnf-testsuite #{testsuite_cmd}"
    run(cmd, log_prefix: "ShellCmd.run_testsuite", force_output: true, joined_output: true)
  end

  # (svteb) TODO: delete in #2171
  def self.cnf_setup(setup_params, cmd_prefix="", expect_failure=false)
    timeout_parameter = setup_params.includes?("timeout") ? "" : "timeout=300"
    result = run_testsuite("cnf_setup #{setup_params} #{timeout_parameter}", cmd_prefix)
    if !expect_failure
      result[:status].success?.should be_true
    else
      result[:status].success?.should be_false
    end
    result
  end

  def self.cnf_cleanup(cleanup_params="", cmd_prefix="", expect_failure=false)
    timeout_parameter = cleanup_params.includes?("timeout") ? "" : "timeout=300"
    result = run_testsuite("cnf_cleanup #{cleanup_params} #{timeout_parameter}", cmd_prefix)
    if !expect_failure
      result[:status].success?.should be_true
    else
      result[:status].success?.should be_false
    end
    result
  end

  def self.environment_cleanup(cleanup_params="", cmd_prefix="")
    timeout_parameter = cleanup_params.includes?("timeout") ? "" : "timeout=300"
    result = run_testsuite("cleanup #{cleanup_params} #{timeout_parameter}", cmd_prefix)
  end
end
