require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/airgap.cr"
require "file_utils"
require "sam"

describe "AirGap" do

  it "'airgapped' should accept a tarball", tags: ["airgap"] do

    AirGap.air_gapped("./tmp/airgapped.tar.gz")
    (File.exists?("./tmp/airgapped.tar.gz")).should be_true
  ensure
    `rm ./tmp/airgapped.tar.gz`
  end

end



