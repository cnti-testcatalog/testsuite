require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "kubectl_client"
require "helm"
require "../../src/tasks/dockerd_setup.cr"
require "file_utils"
require "sam"

def registry_manifest_path
  Path[__DIR__].parent.parent / "tools/registry/manifest.yml"
end

describe "Private Registry: Image" do
  before_all do
    result = ShellCmd.run_testsuite("setup")
    Dockerd.install
    install_registry = KubectlClient::Apply.file(registry_manifest_path)
    KubectlClient::Get.resource_wait_for_install("Pod", "registry")

    Dockerd.exec("apk add curl", force_output: true)
    Dockerd.exec("curl http://example.com", force_output: true)

    if ENV["DOCKERHUB_USERNAME"]? && ENV["DOCKERHUB_PASSWORD"]?
      result = Dockerd.exec("docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD", force_output: true)
      Log.info { "Docker Login output: #{result[:output]}" }
    else
      puts "DOCKERHUB_USERNAME & DOCKERHUB_PASSWORD Must be set.".colorize(:red)
      exit 1
    end

    private_registry = "registry.default.svc.cluster.local:5000"
    Dockerd.exec("docker pull coredns/coredns:1.6.7", force_output: true)
    Dockerd.exec("docker tag coredns/coredns:1.6.7 #{private_registry}/coredns:1.6.7", force_output: true)
    Dockerd.exec("docker push #{private_registry}/coredns:1.6.7", force_output: true)

    # This is required for the test that uses the sample_local_registry_org_image CNF
    Dockerd.exec("docker tag coredns/coredns:1.6.7 #{private_registry}/coredns-sample-org/coredns:1.6.7", force_output: true)
    Dockerd.exec("docker push #{private_registry}/coredns-sample-org/coredns:1.6.7", force_output: true)
  end

  it "'reasonable_image_size' should pass if using local registry and a port", tags: ["private_registry_image"]  do
    cnf="./sample-cnfs/sample_local_registry"

    result = ShellCmd.run_testsuite("cnf_setup cnf-path=#{cnf}")
    result = ShellCmd.run_testsuite("reasonable_image_size verbose")
    result[:status].success?.should be_true
    (/Image size is good/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=#{cnf}")
  end

  it "'reasonable_image_size' should pass if using local registry, a port and an org", tags: ["private_registry_image"]  do
    cnf="./sample-cnfs/sample_local_registry_org_image"

    result = ShellCmd.run_testsuite("cnf_setup cnf-path=#{cnf}")
    result = ShellCmd.run_testsuite("reasonable_image_size verbose")
    result[:status].success?.should be_true
    (/Image size is good/ =~ result[:output]).should_not be_nil
  ensure
    result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=#{cnf}")
  end

  after_all do
    delete_registry = KubectlClient::Delete.file(registry_manifest_path)
    Dockerd.uninstall
  end	
end

describe "Private Registry: Rolling" do
  before_all do
    result = ShellCmd.run_testsuite("setup")
    Dockerd.install
    install_registry = KubectlClient::Apply.file(registry_manifest_path)
    KubectlClient::Get.resource_wait_for_install("Pod", "registry")

    Dockerd.exec("apk add curl", force_output: true)
    Dockerd.exec("curl http://example.com", force_output: true)

    private_registry = "registry.default.svc.cluster.local:5000"
    Dockerd.exec("docker pull coredns/coredns:1.6.7", force_output: true)
    Dockerd.exec("docker tag coredns/coredns:1.6.7 #{private_registry}/coredns:1.6.7", force_output: true)
    Dockerd.exec("docker push #{private_registry}/coredns:1.6.7", force_output: true)

    Dockerd.exec("docker pull coredns/coredns:1.8.0", force_output: true)
    Dockerd.exec("docker tag coredns/coredns:1.8.0 #{private_registry}/coredns:1.8.0", force_output: true)
    Dockerd.exec("docker push #{private_registry}/coredns:1.8.0", force_output: true)
  end

  it "'rolling_update' should pass if using local registry and a port", tags: ["private_registry_rolling"]  do
    begin
      cnf="./sample-cnfs/sample_local_registry_rolling"

      result = ShellCmd.run_testsuite("cnf_setup cnf-path=#{cnf}")
      result = ShellCmd.run_testsuite("rolling_update verbose")
      result[:status].success?.should be_true
      (/Passed/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=#{cnf} wait_count=0")
    end
  end

  it "'rolling_downgrade' should pass if using local registry and a port", tags: ["private_registry_rolling"]  do
    begin
      cnf="./sample-cnfs/sample_local_registry_rolling"

      result = ShellCmd.run_testsuite("cnf_setup cnf-path=#{cnf}")
      result = ShellCmd.run_testsuite("rolling_update verbose")
      result[:status].success?.should be_true
      (/Passed/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=#{cnf} wait_count=0")
  	end
  end

  it "'rolling_version_change' should pass if using local registry and a port", tags: ["private_registry_version"]  do
    begin
      cnf="./sample-cnfs/sample_local_registry_rolling"

      result = ShellCmd.run_testsuite("cnf_setup cnf-path=#{cnf}")
      result = ShellCmd.run_testsuite("rolling_version_change verbose")
      result[:status].success?.should be_true
      (/Passed/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-path=#{cnf} wait_count=0")
    end
  end  

  after_all do
    delete_registry = KubectlClient::Delete.file(registry_manifest_path)
    Dockerd.uninstall
  end	
end
