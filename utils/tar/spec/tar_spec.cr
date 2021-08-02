require "./spec_helper.cr"
# require "../../src/tasks/utils/utils.cr"
# require "../../src/tasks/utils/tar.cr"
require "../tar.cr"
require "../../find/find.cr"
require "file_utils"
require "sam"

describe "TarClient" do

  before_all do
    unless Dir.exists?("./tmp")
      TarClient::LOGGING.info `mkdir ./tmp`
    end
  end
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

  it "'.modify_tar!' should untar file, yield to block, retar", tags: ["tar-install"]  do
    `rm ./tmp/test.tar`
    input_content = File.read("./spec/fixtures/litmus-operator-v1.13.2.yaml") 
    (input_content =~ /imagePullPolicy: Never/).should be_nil
    TarClient.tar("./tmp/test.tar", "./spec/fixtures", "litmus-operator-v1.13.2.yaml")
    TarClient.modify_tar!("./tmp/test.tar") do |directory| 
      template_files = Find.find(directory, "*.yaml*", "100")
      TarClient::LOGGING.debug "template_files: #{template_files}"
      template_files.map do |x| 
        input_content = File.read(x) 
        output_content = input_content.gsub(/(.*imagePullPolicy:)(.*)/,"\\1 Never")

        input_content = File.write(x, output_content) 
      end
    end

    TarClient.untar("./tmp/test.tar", "./tmp")
    (File.exists?("./tmp/litmus-operator-v1.13.2.yaml")).should be_true
    input_content = File.read("./tmp/litmus-operator-v1.13.2.yaml") 
    (input_content =~ /imagePullPolicy: Never/).should_not be_nil
  ensure
    `rm ./tmp/test.tar`
    `rm ./tmp/litmus-operator-v1.13.2.yaml`
  end

end
