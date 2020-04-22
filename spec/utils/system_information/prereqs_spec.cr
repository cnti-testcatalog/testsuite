require "../../spec_helper"
require "colorize"
require "../../../src/tasks/utils/utils.cr"
require "../../../src/tasks/utils/system_information/prereqs.cr"
require "../../../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "Command" do
  it "'prereq' should check the system for prerequisites" do
    response_s = `crystal src/cnf-conformance.cr prereqs verbose`
    puts response_s
    $?.success?.should be_true
    (/helm found/ =~ response_s).should_not be_nil
  end

  it "'helm_global_response()' should return the information about the helm installation" do
    (helm_global_response(true)).should contain("\"v2.")
  end

  it "'helm_local_response()' should return the information about the helm installation" do
    (helm_local_response(true)).should contain("\"v3.")
  end

  it "'helm_version()' should return the information about the helm version" do
    (helm_version(helm_local_response)).should contain("v3.")
  end

  it "'helm_installations()' should return the information about the helm installation" do
    (helm_installations(true)).should contain("helm found")
  end
end
