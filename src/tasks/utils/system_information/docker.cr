require "file_utils"
require "colorize"
require "totem"

# todo collection in modules similar to ohai:
# https://github.com/chef/ohai

class DockerVersion
  property global_version
  getter global_version

  property local_version
  getter local_version

  def initialize(@global_version : String, @local_version : String)
  end

  def installed? : Bool
    if local_version.empty? && global_version.empty?
      return false
    end
    return true
  end
end

def docker_version_info(verbose=false) : DockerVersion
  gdocker = docker_global_response(verbose)
  Log.for("verbose:global_docker_version").info { gdocker } if verbose
  global_version = parse_docker_version(gdocker, verbose)

  ldocker = docker_local_response(verbose)
  Log.for("verbose:local_docker_version").info { ldocker } if verbose
  local_version = parse_docker_version(ldocker, verbose)

  DockerVersion.new(global_version, local_version)
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

def parse_docker_version(docker_response, verbose=false)
  resp = docker_response.match /Version: .*([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})/
  VERBOSE_LOGGING.info resp if verbose
  if resp
    "#{resp && resp.not_nil![1]}"
  else
    ""
  end
end


