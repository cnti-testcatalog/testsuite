require "file_utils"
require "colorize"
require "totem"

def kubectl_installation(verbose = false, offline_mode = false)
  gmsg = "No Global kubectl version found"
  lmsg = "No Local kubectl version found"
  gkubectl = kubectl_global_response
  VERBOSE_LOGGING.info gkubectl if verbose

  global_kubectl_version = kubectl_version(gkubectl, "client", verbose)

  if !global_kubectl_version.empty?
    gmsg = "Global kubectl found. Version: #{global_kubectl_version}"
    stdout_success gmsg

    version_test = acceptable_kubectl_version?(gkubectl, verbose)
    if version_test == false
      stdout_warning "Global kubectl client is more than 1 minor version ahead/behind server version"
    elsif version_test.nil? && offline_mode == false
      stdout_warning "Global kubectl client version could not be checked for compatibility with server. (Server not configured?)"
    elsif version_test.nil? && offline_mode == true
      stdout_warning "Global kubectl client version could not be checked for compatibility with server. Running in offline mode"
    end
  else
    stdout_warning gmsg
  end

  lkubectl = kubectl_local_response
  VERBOSE_LOGGING.info lkubectl if verbose

  local_kubectl_version = kubectl_version(lkubectl, "client", verbose)

  if !local_kubectl_version.empty?
    lmsg = "Local kubectl found. Version: #{local_kubectl_version}"
    stdout_success lmsg

    version_test = acceptable_kubectl_version?(lkubectl, verbose)
    if version_test == false
      stdout_warning "Local kubectl client is more than 1 minor version ahead/behind server version"
    elsif version_test.nil? && offline_mode == false
      stdout_warning "Local kubectl client version could not be checked for compatibility with server. (Server not configured?)"
    elsif version_test.nil? && offline_mode == true
      stdout_warning "Local kubectl client version could not be checked for compatibility with server. Running in offline mode"
    end
  else
    stdout_warning lmsg
  end

  # uncomment to fail the installation check
  # global_kubectl_version = nil
  # local_kubectl_version = nil
  # gmsg = "No Global kubectl version found"
  # lmsg = "No Local kubectl version found"
  if global_kubectl_version.empty? && local_kubectl_version.empty?
    stdout_failure "Kubectl not found"
    stdout_failure %Q(
    Linux installation instructions for Kubectl can be found here: https://kubernetes.io/docs/tasks/tools/install-kubectl/

    Install kubectl binary with curl on Linux
    Download the latest release with the command:

    curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
    To download a specific version, replace the $(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) portion of the command with the specific version.

      For example, to download version v1.18.0 on Linux, type:

      curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
    Make the kubectl binary executable.

      chmod +x ./kubectl
    Move the binary in to your PATH.

      sudo mv ./kubectl /usr/local/bin/kubectl
    Test to ensure the version you installed is up-to-date:

      kubectl version --client
    )
  end
  "#{lmsg} #{gmsg}"
end

def kubectl_global_response(verbose = false)
  status = Process.run("kubectl version", shell: true, output: kubectl_response = IO::Memory.new, error: stderr = IO::Memory.new)
  VERBOSE_LOGGING.info kubectl_response if verbose
  kubectl_response.to_s
end

def kubectl_local_response(verbose = false)
  current_dir = FileUtils.pwd
  VERBOSE_LOGGING.info current_dir if verbose
  kubectl = "#{current_dir}/#{TOOLS_DIR}/kubectl/linux-amd64/kubectl"
  status = Process.run("#{kubectl} version", shell: true, output: kubectl_response = IO::Memory.new, error: stderr = IO::Memory.new)
  VERBOSE_LOGGING.info kubectl_response.to_s if verbose
  kubectl_response.to_s
end

# Extracts Kubernetes client version or server version
#
# ```
# version = kubectl_version(kubectl_response, "client")
# version # => "1.12"
#
# version = kubectl_version(kubectl_response, "server")
# version # => "1.12"
# ```
#
# For reference, below are example client and server version strings from "kubectl version" output
#
# ```
# Client Version: version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.0", GitCommit:"cb303e613a121a29364f75cc67d3d580833a7479", GitTreeState:"clean", BuildDate:"2021-04-08T16:31:21Z", GoVersion:"go1.16.1", Compiler:"gc", Platform:"linux/amd64"}
# Server Version: version.Info{Major:"1", Minor:"20", GitVersion:"v1.20.2", GitCommit:"faecb196815e248d3ecfb03c680a4507229c2a56", GitTreeState:"clean", BuildDate:"2021-01-21T01:11:42Z", GoVersion:"go1.15.5", Compiler:"gc", Platform:"linux/amd64"}
# ```
#
# TODO Function could be updated to rely on the JSON output of "kubectl version -o json" instead of regex parsing
#
# Returns the version as a string (Example: 1.12, 1.20, etc)
def kubectl_version(kubectl_response, version_for = "client", verbose = false)
  # version_for can be "client" or "server"
  resp = kubectl_response.match /#{version_for.capitalize} Version: version.Info{(Major:"(([0-9]{1,3})"\, )Minor:"([0-9]{1,3}[+]?)")/
  VERBOSE_LOGGING.info resp if verbose

  if resp
    "#{resp && resp.not_nil![3]}.#{resp && resp.not_nil![4]}"
  else
    ""
  end
end

# Check if client version is not 3 minor versions behind server version
def acceptable_kubectl_version?(kubectl_response, verbose = false)
  client_version = kubectl_version(kubectl_response, "client", verbose).gsub("+", "").split(".")
  server_version = kubectl_version(kubectl_response, "server", verbose).gsub("+", "")

  # Return nil to indicate comparison was not possible due to missing server version.
  if server_version == ""
    return nil
  end

  server_version = server_version.split(".")

  # This check ensures major versions are same
  return false if server_version[0].to_i != client_version[0].to_i

  # This checks for minor versions
  server_minor_version = server_version[1].to_i
  client_minor_version = client_version[1].to_i

  # https://kubernetes.io/releases/version-skew-policy/
  # kubectl cannot be more than +/- 1 minor version away from the server
  return false if client_minor_version < (server_minor_version - 1) || client_minor_version > (server_minor_version + 1)
  return true
end
