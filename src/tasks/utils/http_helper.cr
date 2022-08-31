require "colorize"

module HttpHelper 
  # avoids problems with ssl
  def self.download(url, filename)
    Log.info {"download: #{url}, #{filename}"}

    if KernelIntrospection.os_release_id =~ /rhel/ ||
        KernelIntrospection.os_release_id =~ /centos/ #lol
      Log.info {"rhel ssl"}
      context = OpenSSL::SSL::Context::Client.insecure
    else
      Log.info {"non-rhel ssl"}
      context = OpenSSL::SSL::Context::Client.new 
    end

    resp = Halite.follow.get(url, tls: context) do |response|
      Log.info {"response status: #{response.status_code}"}
      # body = response.body_io.gets_to_end # this is going to be a problem
      # Log.info {"response response.body: #{body}"}
      File.write(filename, body_io)
    end

    resp 
  end
end
