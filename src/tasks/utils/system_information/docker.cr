require "file_utils"
require "colorize"
require "totem"

# todo collection in modules similar to ohai:
# https://github.com/chef/ohai
def docker_installation(verbose=false)
  gmsg = "No Global docker version found"
  lmsg = "No Local docker version found"
  gdocker = docker_global_response(verbose)
  VERBOSE_LOGGING.info gdocker if verbose
  
  global_docker_version = docker_version(gdocker, verbose)
   
  if !global_docker_version.empty?
    gmsg = "Global docker found. Version: #{global_docker_version}"
    stdout_success gmsg
  else
    stdout_warning gmsg
  end

  ldocker = docker_local_response(verbose)
  VERBOSE_LOGGING.info ldocker if verbose
  
  local_docker_version = docker_version(ldocker, verbose)
   
  if !local_docker_version.empty?
    lmsg = "Local docker found. Version: #{local_docker_version}"
    stdout_success lmsg
  else
    stdout_warning lmsg
  end

  # uncomment to fail the installation check
  # global_docker_version = nil
  # local_docker_version = nil
  # gmsg = "No Global docker version found"
  # lmsg = "No Local docker version found"
  if global_docker_version.empty? && local_docker_version.empty?
    stdout_failure "docker not found"
    stdout_failure %Q(
    Linux installation instructions for docker can be found here: https://docs.docker.com/engine/install 

    Test to ensure the version you installed is up-to-date:

      docker version
    )
  end
  "#{lmsg} #{gmsg}"
end 

def docker_global_response(verbose=false)
  docker_response = `docker version`
  VERBOSE_LOGGING.info docker_response if verbose
  docker_response 
end

def docker_local_response(verbose=false)
  current_dir = FileUtils.pwd 
  VERBOSE_LOGGING.info current_dir if verbose 
  docker = "#{current_dir}/#{TOOLS_DIR}/docker/linux-amd64/docker"
  # docker_response = `#{docker} version`
  status = Process.run("#{docker} version", shell: true, output: docker_response = IO::Memory.new, error: stderr = IO::Memory.new)

  VERBOSE_LOGGING.info docker_response.to_s if verbose
  docker_response.to_s
end

def docker_version(docker_response, verbose=false)
  resp = docker_response.match /Version: .*([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})/
  VERBOSE_LOGGING.info resp if verbose
  if resp
    "#{resp && resp.not_nil![1]}"
  else
    ""
  end
end


