require "../../spec_helper"
require "colorize"
require "../../../src/tasks/utils/utils.cr"
require "../../../src/tasks/prereqs.cr"
require "../../../src/tasks/utils/system_information/kubectl.cr"
require "file_utils"
require "sam"

describe "Kubectl" do

  it "'kubectl_global_response()' should return the information about the kubectl installation", tags: ["kubectl-utils"]  do
    (kubectl_global_response(true)).should contain("Client Version")
  end

  it "'kubectl_local_response()' should return the information about the kubectl installation", tags: ["kubectl-utils"]  do
    (kubectl_local_response(true)).should eq("") 
  end

  it "'kubectl_version()' should return the information about the kubectl version", tags: ["kubectl-utils"]  do
    (kubectl_version(kubectl_global_response)).should match(/(([0-9]{1,3}[\.]){1,2}[0-9]{1,3}[+]?)/)
    (kubectl_version(kubectl_local_response)).should contain("")
  end

  it "'kubectl_installations()' should return the information about the kubectl installation", tags: ["kubectl-utils"]  do
    (kubectl_installation(true)).should contain("kubectl found")
  end
end
