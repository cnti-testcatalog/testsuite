require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "../src/tasks/utils/airgap.cr"
require "file_utils"
require "sam"

describe "AirGap" do

  before_each do
    `./cnf-testsuite cleanup`
    $?.success?.should be_true
    unless Dir.exists?("./tmp")
      LOGGING.info `mkdir ./tmp`
    end
  end

  it "'airgapped' task should accept a tarball", tags: ["airgap"] do

    LOGGING.info `./cnf-testsuite airgapped output-file=./tmp/airgapped.tar.gz`
    (File.exists?("./tmp/airgapped.tar.gz")).should be_true
  ensure
    `rm ./tmp/airgapped.tar.gz`
  end

end



