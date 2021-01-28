require "file_utils"
require "colorize"
require "totem"

def kubectl_installation(verbose=false)
  gmsg = "No Global kubectl version found"
  lmsg = "No Local kubectl version found"
  gkubectl = kubectl_global_response
  VERBOSE_LOGGING.info gkubectl if verbose
  
  global_kubectl_version = kubectl_version(gkubectl, verbose)
   
  if !global_kubectl_version.empty?
    gmsg = "Global kubectl found. Version: #{global_kubectl_version}"
    stdout_success gmsg
  else
    stdout_warning gmsg
  end

  lkubectl = kubectl_local_response
  VERBOSE_LOGGING.info lkubectl if verbose
  
  local_kubectl_version = kubectl_version(lkubectl, verbose)
   
  if !local_kubectl_version.empty?
    lmsg = "Local kubectl found. Version: #{local_kubectl_version}"
    stdout_success lmsg
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

def kubectl_global_response(verbose=false)
  kubectl_response = `kubectl version`
  VERBOSE_LOGGING.info kubectl_response if verbose
  kubectl_response 
end

def kubectl_local_response(verbose=false)
  current_dir = FileUtils.pwd 
  VERBOSE_LOGGING.info current_dir if verbose 
  kubectl = "#{current_dir}/#{TOOLS_DIR}/kubectl/linux-amd64/kubectl"
  # kubectl_response = `#{kubectl} version`
  status = Process.run("#{kubectl} version", shell: true, output: kubectl_response = IO::Memory.new, error: stderr = IO::Memory.new)
  VERBOSE_LOGGING.info kubectl_response.to_s if verbose
  kubectl_response.to_s
end

# TODO create a kubernetes version checker (vs kubectl client checker)

def kubectl_version(kubectl_response, verbose=false)
  # example
  # Client Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.3", GitCommit:"2d3c76f9091b6bec110a5e63777c332469e0cba2", GitTreeState:"clean", BuildDate:"2019-08-19T11:13:54Z", GoVersion:"go1.12.9", Compiler:"gc", Platform:"linux/amd64"} 
  resp = kubectl_response.match /Client Version: version.Info{(Major:"(([0-9]{1,3})"\, )Minor:"([0-9]{1,3}[+]?)")/
  VERBOSE_LOGGING.info resp if verbose
  if resp
    "#{resp && resp.not_nil![3]}.#{resp && resp.not_nil![4]}"
  else
    ""
  end
end


