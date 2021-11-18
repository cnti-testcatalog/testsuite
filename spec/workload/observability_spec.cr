require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"

describe "Observability" do
  it "'log_output' should pass with a cnf that outputs logs to stdout", tags: ["observability"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      response_s = `./cnf-testsuite log_output verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Resources output logs to stdout and stderr/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
    end
  end

  it "'log_output' should fail with a cnf that does not output logs to stdout", tags: ["observability"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_no_logs/cnf-testsuite.yml`
      response_s = `./cnf-testsuite log_output verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Resources do not output logs to stdout and stderr/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample_no_logs/cnf-testsuite.yml`
    end
  end
end