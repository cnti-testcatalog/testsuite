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
    # (kosstennbl) TODO: Test and specs for 'oran_e2_connection' should be redesigned. Check #2153 for more info. Spec was using sample_srsran_ueauth_open5gs and sample-oran-ric.
  end

  it "'oran_e2_connection' should fail if the ORAN enabled RAN does not connect to the RIC using the e2 standard", tags: ["oran"]  do
    # (kosstennbl) TODO: Test and specs for 'oran_e2_connection' should be redesigned. Check #2153 for more info. Spec was using sample_srsran_ueauth_open5gs and sample-oran-noric.
  end

end
