require "../../spec_helper"
require "colorize"
require "../../../src/tasks/utils/utils.cr"
require "../../../src/tasks/prereqs.cr"
require "../../../src/tasks/utils/system_information/kubectl.cr"
require "file_utils"
require "sam"

describe "Kubectl" do
  it "'kubectl_global_response()' should return the information about the kubectl installation", tags: ["kubectl-utils"] do
    (kubectl_global_response(true)).should contain("Client Version")
  end

  it "'kubectl_local_response()' should return the information about the kubectl installation", tags: ["kubectl-utils"] do
    (kubectl_local_response(true)).should eq("")
  end

  it "'kubectl_version()' should return the information about the kubectl version", tags: ["kubectl-utils"] do
    (kubectl_version(kubectl_global_response)).should match(/(([0-9]{1,3}[\.]){1,2}[0-9]{1,3}[+]?)/)
    (kubectl_version(kubectl_local_response)).should contain("")
  end

  it "'kubectl_installations()' should return the information about the kubectl installation", tags: ["kubectl-utils"] do
    (kubectl_installation(true)).should contain("kubectl found")
  end

  it "'acceptable_kubectl_version?()' should return true if client is within 1 minor version ahead/behind server version'", tags: ["kubectl-utils"] do
    kubectl_response = <<-KUBECTL_OUTPUT
      Client Version: version.Info{Major:"1", Minor:"19", GitVersion:"v1.21.0", GitCommit:"cb303e613a121a29364f75cc67d3d580833a7479", GitTreeState:"clean", BuildDate:"2021-04-08T16:31:21Z", GoVersion:"go1.16.1", Compiler:"gc", Platform:"linux/amd64"}
      Server Version: version.Info{Major:"1", Minor:"20", GitVersion:"v1.20.2", GitCommit:"faecb196815e248d3ecfb03c680a4507229c2a56", GitTreeState:"clean", BuildDate:"2021-01-21T01:11:42Z", GoVersion:"go1.15.5", Compiler:"gc", Platform:"linux/amd64"}
    KUBECTL_OUTPUT

    acceptable_kubectl_version?(kubectl_response).should eq(true)

    kubectl_response = <<-KUBECTL_OUTPUT
      Client Version: version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.0", GitCommit:"cb303e613a121a29364f75cc67d3d580833a7479", GitTreeState:"clean", BuildDate:"2021-04-08T16:31:21Z", GoVersion:"go1.16.1", Compiler:"gc", Platform:"linux/amd64"}
      Server Version: version.Info{Major:"1", Minor:"20", GitVersion:"v1.20.2", GitCommit:"faecb196815e248d3ecfb03c680a4507229c2a56", GitTreeState:"clean", BuildDate:"2021-01-21T01:11:42Z", GoVersion:"go1.15.5", Compiler:"gc", Platform:"linux/amd64"}
    KUBECTL_OUTPUT

    acceptable_kubectl_version?(kubectl_response).should eq(true)
  end

  it "'acceptable_kubectl_version?()' should return false if client is more than 1 minor version ahead/behind server version'", tags: ["kubectl-utils"] do
    kubectl_response = <<-KUBECTL_OUTPUT
      Client Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.21.0", GitCommit:"cb303e613a121a29364f75cc67d3d580833a7479", GitTreeState:"clean", BuildDate:"2021-04-08T16:31:21Z", GoVersion:"go1.16.1", Compiler:"gc", Platform:"linux/amd64"}
      Server Version: version.Info{Major:"1", Minor:"20", GitVersion:"v1.20.2", GitCommit:"faecb196815e248d3ecfb03c680a4507229c2a56", GitTreeState:"clean", BuildDate:"2021-01-21T01:11:42Z", GoVersion:"go1.15.5", Compiler:"gc", Platform:"linux/amd64"}
    KUBECTL_OUTPUT

    acceptable_kubectl_version?(kubectl_response).should eq(false)

    kubectl_response = <<-KUBECTL_OUTPUT
      Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.21.0", GitCommit:"cb303e613a121a29364f75cc67d3d580833a7479", GitTreeState:"clean", BuildDate:"2021-04-08T16:31:21Z", GoVersion:"go1.16.1", Compiler:"gc", Platform:"linux/amd64"}
      Server Version: version.Info{Major:"1", Minor:"20", GitVersion:"v1.20.2", GitCommit:"faecb196815e248d3ecfb03c680a4507229c2a56", GitTreeState:"clean", BuildDate:"2021-01-21T01:11:42Z", GoVersion:"go1.15.5", Compiler:"gc", Platform:"linux/amd64"}
    KUBECTL_OUTPUT

    acceptable_kubectl_version?(kubectl_response).should eq(false)
  end
end
