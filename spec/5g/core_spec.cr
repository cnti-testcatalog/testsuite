require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/kind_setup.cr"
require "file_utils"
require "sam"

describe "Core" do

  before_all do
    `./cnf-testsuite setup`
    $?.success?.should be_true
  end

  it "'smf_upf_heartbeat' should pass if the smf_upf core is resilient to network latency", tags: ["core"]  do
    begin
      Log.info {`./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_open5gs/cnf-testsuite.yml`}
      $?.success?.should be_true
      response_s = `./cnf-testsuite smf_upf_heartbeat verbose`
      Log.info {"response: #{response_s}"}
      (/PASSED: Chaos service degradation is less than 50%/ =~ response_s).should_not be_nil
    ensure
      Log.info {`./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample_open5gs/cnf-testsuite.yml`}
      $?.success?.should be_true
    end
  end

  it "'smf_upf_heartbeat' should fail if the smf_upf core is not resilient to network latency", tags: ["core"]  do
    begin
      Log.info {`./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_open5gs/cnf-testsuite.yml`}
      $?.success?.should be_true
      response_s = `./cnf-testsuite smf_upf_heartbeat verbose`
      Log.info {"response: #{response_s}"}
      (/FAILED: Chaos service degradation is more than 50%/ =~ response_s).should_not be_nil
    ensure
      Log.info {`./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample_open5gs/cnf-testsuite.yml`}
      $?.success?.should be_true
    end
  end

end
