# coding: utf-8

# To avoid circular dependencies:
# airgap uses airgaputils
# airgap uses tar
# tar uses airgaputils
module AirGapUtils

  def self.image_pull_policy(file, output_file="")
    input_content = File.read(file) 
    # output_content = input_content.gsub("imagePullPolicy: Always", "imagePullPolicy: Never")
    output_content = input_content.gsub(/(.*imagePullPolicy:)(.*)/,"\\1 Never")

    LOGGING.debug "pull policy found?: #{input_content =~ /(.*imagePullPolicy:)(.*)/}"
    LOGGING.debug "output_content: #{output_content}"
    if output_file.empty?
      input_content = File.write(file, output_content) 
    else
      input_content = File.write(output_file, output_content) 
    end
    #
    #TODO find out why this doesn't work
    LOGGING.debug "input_content: #{input_content}"
  end
end
