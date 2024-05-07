require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/kind_setup.cr"
require "file_utils"
require "sam"

describe "5g" do

  before_all do
    result = ShellCmd.run_testsuite("setup")
    result[:status].success?.should be_true
  end


  it "'oran_e2_connection' should pass if the ORAN enabled RAN connects to the RIC using the e2 standard", tags: ["oran"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample_srsran_ueauth_open5gs/cnf-testsuite.yml") 
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-oran-ric/cnf-testsuite.yml") 
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("oran_e2_connection verbose")
      (/(PASSED).*(RAN connects to a RIC using the e2 standard interface)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-oran-ric/cnf-testsuite.yml") 
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample_open5gs/cnf-testsuite.yml") 
      result[:status].success?.should be_true
    end
  end

  it "'oran_e2_connection' should fail if the ORAN enabled RAN does not connect to the RIC using the e2 standard", tags: ["oran"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample_srsran_ueauth_open5gs/cnf-testsuite.yml") 
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-oran-noric/cnf-testsuite.yml") 
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("oran_e2_connection verbose")
      (/(FAILED).*(RAN does not connect to a RIC using the e2 standard interface)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample_open5gs/cnf-testsuite.yml") 
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-oran-noric/cnf-testsuite.yml") 
      result[:status].success?.should be_true
    end
  end

end
