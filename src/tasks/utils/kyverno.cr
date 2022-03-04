module Kyverno
  VERSION = "1.5.0"

  def self.install
    result = KubectlClient::Apply.file(manifest_url)
    return false if !result[:status].success?

    download_policies_repo
    KubectlClient::Get.resource_wait_for_install("deployment", "kyverno", 180, "kyverno")
  end

  def self.uninstall
    result = KubectlClient::Delete.file(manifest_url)
    delete_policies_repo
    KubectlClient::Get.resource_wait_for_uninstall("deployment", "kyverno", 180, "kyverno")
  end

  def self.manifest_url
    "https://raw.githubusercontent.com/kyverno/kyverno/v#{VERSION}/definitions/release/install.yaml"
  end

  def self.policies_repo_path
    "#{tools_path}/kyverno-policies"
  end

  def self.download_policies_repo
    url = "https://github.com/kyverno/policies.git"
    result = GitClient.clone("#{url} #{policies_repo_path}")
    result[:status].success?
  end

  def self.delete_policies_repo
    FileUtils.rm_rf(policies_repo_path)
  end

  module PolicyReport
    def self.all()
      cmd = "kubectl get polr -A -o json"
      ShellCmd.run(cmd, "Kyverno::PolicyReport.all")
    end

    def self.get(name : String)
      cmd = "kubectl get polr #{name} -o json"
      ShellCmd.run(cmd, "Kyverno::PolicyReport.get")
    end

    def self.delete_all()
      cmd = "kubectl delete polr --all -A"
      result = ShellCmd.run(cmd, "Kyverno::PolicyReport.delete_all")
      result[:status].success?
    end
  end

  module ClusterPolicy
    def self.all()
      cmd = "kubectl get cpol -o json"
      ShellCmd.run(cmd, "Kyverno::ClusterPolicy.all")
    end

    def self.delete_all()
      cmd = "kubectl delete cpol --all -A"
      result = ShellCmd.run(cmd, "Kyverno::ClusterPolicy.delete_all")
      result[:status].success?
    end
  end

  # NOTE: Not used anywhere. Retaining until the entire Kyverno PR is merged.
  # def self.policy_report_failed(name : String)
  #   cmd = "kubectl get polr -A -o yaml | grep \"result: fail\" -B10 | grep #{name} -B2 -A7"
  #   ShellCmd.run(cmd, "KubectlClient::Get.policy_report_failed")
  # end
end
