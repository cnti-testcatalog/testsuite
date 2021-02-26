require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"

module DockerClient
  module Get
    def self.image_tags(image_name) : Halite::Response 
      LOGGING.info "tags image name: #{image_name}"
      # if image doesn't have a / in it, it has no user and is an official docker reposistory
      # these are prefixed with library/
      # if there are three elements in the array, use the last two elements as the org/image:tag combo
      # if there are two elements in the array, use both elements as the image/tag combo
      if image_name.split("/").size > 2
        image_name = "#{image_name.split("/")[1]}/#{image_name.split("/")[2]}"
      end
      LOGGING.info "org/image:tag : #{image_name}"
      modified_image_with_repo = ((image_name =~ /\//) == nil) ? "library/" + image_name : image_name
 
      LOGGING.info "docker halite url: #{"https://hub.docker.com/v2/repositories/#{modified_image_with_repo}/tags/?page_size=100"}"
      docker_resp = Halite.get("https://hub.docker.com/v2/repositories/#{modified_image_with_repo}/tags/?page_size=100", headers: {"Authorization" => "JWT"})
      LOGGING.debug "docker image resp: #{docker_resp}"
      docker_resp
    end
    
    def self.image_by_tag(docker_image_list, tag)
      # if image_tag = nil then get latest tag
      modified_tag = tag == nil ? "latest" : tag
      latest_image = docker_image_list.parse("json")["results"].as_a.find{|x|x["name"]=="#{modified_tag}"} 
      LOGGING.debug "docker parse resp: #{latest_image}"
      (LOGGING.error "no image found for tag: #{modified_tag}") if latest_image == nil
      latest_image 
    end
  end
end
