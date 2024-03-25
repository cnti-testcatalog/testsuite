require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/kind_setup.cr"
require "file_utils"
require "sam"

describe "5g" do

  before_all do
    `./cnf-testsuite setup`
    $?.success?.should be_true
  end


  it "'oran_e2_connection' should pass if the ORAN enabled RAN connects to the RIC using the e2 standard", tags: ["oran"]  do
    begin
      response_s = `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_srsran_ueauth_open5gs/cnf-testsuite.yml`
      Log.info {response_s}
      $?.success?.should be_true
      response_s = `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-oran-ric/cnf-testsuite.yml`
      Log.info {response_s}
      $?.success?.should be_true
      response_s = `./cnf-testsuite oran_e2_connection verbose`
      Log.info {"response: #{response_s}"}
      (/PASSED: RAN connects to a RIC using the e2 standard interface/ =~ response_s).should_not be_nil
    ensure
      response_s = `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-oran-ric/cnf-testsuite.yml`
      Log.info {response_s}
      $?.success?.should be_true
      response_s = `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample_open5gs/cnf-testsuite.yml`
      Log.info {response_s}
      $?.success?.should be_true
    end
  end

  it "'oran_e2_connection' should fail if the ORAN enabled RAN does not connect to the RIC using the e2 standard", tags: ["oran"]  do
    begin
      response_s = `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_srsran_ueauth_open5gs/cnf-testsuite.yml`
      Log.info {response_s}
      $?.success?.should be_true
      response_s = `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-oran-noric/cnf-testsuite.yml`
      Log.info {response_s}
      $?.success?.should be_true
      response_s = `./cnf-testsuite oran_e2_connection verbose`
      Log.info {"response: #{response_s}"}
      (/FAILED: RAN does not connect to a RIC using the e2 standard interface/ =~ response_s).should_not be_nil
    ensure
      response_s = `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample_open5gs/cnf-testsuite.yml`
      Log.info {response_s}
      $?.success?.should be_true
      response_s = `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-oran-noric/cnf-testsuite.yml`
      Log.info {response_s}
      $?.success?.should be_true
    end
  end

end
