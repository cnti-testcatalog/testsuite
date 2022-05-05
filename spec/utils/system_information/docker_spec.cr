require "../../spec_helper"
require "colorize"
require "../../../src/tasks/utils/utils.cr"
require "../../../src/tasks/prereqs.cr"
require "../../../src/tasks/utils/system_information/docker.cr"
require "file_utils"
require "sam"

describe "Docker" do

  it "'docker_global_response()' should return the information about the docker installation", tags: ["docker-prereq"]  do
    (docker_global_response(true)).should contain("Docker Engine")
  end

  it "'docker_local_response()' should return the information about the docker installation", tags: ["docker-prereq"]  do
    (docker_local_response(true)).should eq("") 
  end

  it "'docker_version()' should return the information about the docker version", tags: ["docker-prereq"]  do
    (docker_version(docker_global_response)).should match(/(([0-9]{1,3}[\.]){1,2}[0-9]{1,3})/)
    (docker_version(docker_local_response)).should contain("")
  end

  it "'docker_installations()' should return the information about the docker installation", tags: ["docker-prereq"]  do
    (docker_installation(true)).should contain("docker found")
  end
end
