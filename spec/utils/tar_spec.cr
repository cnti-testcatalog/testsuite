require "../spec_helper"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/tar.cr"
require "file_utils"
require "sam"

describe "TarClient" do

  it "'.tar' should tar a source file or directory", tags: ["tar-install"]  do
    `rm ./tmp/test.tar`
    TarClient.tar("./tmp/test.tar", "./spec/fixtures", "cnf-testsuite.yml")
    (File.exists?("./spec/fixtures/cnf-testsuite.yml")).should be_true
  ensure
    `rm ./tmp/test.tar`
  end

  it "'.untar' should untar a tar file into a directory", tags: ["tar-install"]  do
    `rm ./tmp/test.tar`
    TarClient.tar("./tmp/test.tar", "./spec/fixtures", "cnf-testsuite.yml")
    TarClient.untar("./tmp/test.tar", "./tmp")
    (File.exists?("./tmp/cnf-testsuite.yml")).should be_true
  ensure
    `rm ./tmp/test.tar`
    `rm ./tmp/cnf-testsuite.yml`
  end
end
