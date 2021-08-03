require "./kubectl_client.cr"
# require "./airgap_utils.cr"

def self.image_pull(yml)
  containers  = yml.map { |y|
    mc = Helm::Manifest.manifest_containers(y)
    mc.as_a? if mc
  }.flatten.compact

  images =  containers.flatten.map {|x|
    LOGGING.debug "container x: #{x}"
    image = x.dig?("image")
    # if image
    #   LOGGING.debug "image: #{image.as_s}"
    #   parsed_image = DockerClient.parse_image(image.as_s)
    #   image = "#{parsed_image["complete_fqdn"]}"
    # end
    image
  }.compact
  LOGGING.info "Images: #{images}"

  resp = AirGap.create_pod_by_image("conformance/cri-tools:latest", "cri-tools")

  images.map do |image| 
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")
    pods.map do |pod| 
      KubectlClient.exec("-ti #{pod.dig?("metadata", "name")} -- crictl pull #{image}")
    end
  end
end
