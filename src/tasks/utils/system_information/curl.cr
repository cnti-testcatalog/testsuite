require "file_utils"
require "colorize"
require "totem"

def curl_installation()
  gmsg = "No Global curl version found"
  lmsg = "No Local curl version found"
  gcurl = curl_global_response
  Log.debug { gcurl }
  
  global_curl_version = curl_version(gcurl)
   
  if !global_curl_version.empty?
    gmsg = "Global curl found. Version: #{global_curl_version}"
    stdout_success gmsg
  else
    stdout_warning gmsg
  end

  lcurl = curl_local_response
  Log.debug { lcurl }
  
  local_curl_version = curl_version(lcurl)
   
  if !local_curl_version.empty?
    lmsg = "Local curl found. Version: #{local_curl_version}"
    stdout_success lmsg
  else
    stdout_warning lmsg
  end

  if global_curl_version.empty? && local_curl_version.empty?
    stdout_failure "Curl not found"
    stdout_failure %Q(
    Linux installation instructions for Curl can be found here: https://www.tecmint.com/install-curl-in-linux/ 
    )
  end
  "#{lmsg} #{gmsg}"
end 

def curl_global_response()
  status = Process.run("curl --version", shell: true, output: curl_response = IO::Memory.new, error: stderr = IO::Memory.new)
  Log.debug { curl_response }
  curl_response.to_s
end

def curl_local_response()
  current_dir = FileUtils.pwd
  Log.debug { current_dir }
  curl = "#{tools_path}/curl/linux-amd64/curl"
  status = Process.run("#{curl} --version", shell: true, output: curl_response = IO::Memory.new, error: stderr = IO::Memory.new)
  Log.debug { curl_response.to_s }
  curl_response.to_s
end

def curl_version(curl_response)
  # example
  # GNU Curl 1.15 built on linux-gnu.
  resp = curl_response.match /curl (([0-9]{1,3}[\.]){1,2}[0-9]{1,3})/
  Log.debug { resp }
  "#{resp && resp.not_nil![1]}"
end
