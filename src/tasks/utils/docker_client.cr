require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"

module DockerClient
  module Get
    def self.images(image_tag) : Halite::Response 
      LOGGING.debug "images image_tag: #{image_tag}"
      # if image doesn't have a / in it, it has no user and is an official docker reposistory
      # these are prefixed with library/
      modified_image_with_repo = ((image_tag =~ /\//) == nil) ? "library/" + image_tag : image_tag
 
      LOGGING.debug "docker halite url: #{"https://hub.docker.com/v2/repositories/#{modified_image_with_repo}/tags/?page_size=100"}"
      docker_resp = Halite.get("https://hub.docker.com/v2/repositories/#{modified_image_with_repo}/tags/?page_size=100", headers: {"Authorization" => "JWT"})
      LOGGING.debug "docker image resp: #{docker_resp}"
      docker_resp
    end
    
    def self.latest_image(docker_image_list, tag)
      # if image_tag = nil then get latest tag
      modified_tag = tag == nil ? "latest" : tag
      latest_image = docker_image_list.parse("json")["results"].as_a.find{|x|x["name"]=="#{modified_tag}"} 
      LOGGING.debug "docker parse resp: #{latest_image}"
      latest_image 
    end
  end
end
