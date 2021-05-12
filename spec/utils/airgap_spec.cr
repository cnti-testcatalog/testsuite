require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/airgap.cr"
require "file_utils"
require "sam"

describe "AirGap" do
    unless Dir.exists?("./tmp")
      LOGGING.info `mkdir ./tmp`
    end

  it "'generate' should generate a tarball", tags: ["airgap"] do

    AirGap.generate("./tmp/airgapped.tar.gz")
    (File.exists?("./tmp/airgapped.tar.gz")).should be_true
  ensure
    `rm ./tmp/airgapped.tar.gz`
  end

end



