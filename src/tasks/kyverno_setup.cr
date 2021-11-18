# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Install Kyverno"
task "install_kyverno" do |_, args|
  kyverno_version="1.4.3"
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  url = "https://raw.githubusercontent.com/kyverno/kyverno/v#{kyverno_version}/definitions/release/install.yaml"
  result = KubectlClient::Apply.file(url)

  if !result[:status].success?
    # fail and exit
  end

  is_ready = KubectlClient::Get.resource_wait_for_install("deployment", "kyverno", 180, "kyverno")
  if is_ready
    stdout_success "Kyverno successfully installed"
  end
end

