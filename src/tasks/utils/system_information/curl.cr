require "file_utils"
require "colorize"
require "totem"

def curl_installation(verbose=false)
  gmsg = "No Global curl version found"
  lmsg = "No Local curl version found"
  gcurl = curl_global_response
  puts gcurl if verbose
  
  global_curl_version = curl_version(gcurl, verbose)
   
  if !global_curl_version.empty?
    gmsg = "Global curl found. Version: #{global_curl_version}"
    puts gmsg.colorize(:green)
  else
    puts gmsg.colorize(:yellow)
  end

  lcurl = curl_local_response
  puts lcurl if verbose
  
  local_curl_version = curl_version(lcurl, verbose)
   
  if !local_curl_version.empty?
    lmsg = "Local curl found. Version: #{local_curl_version}"
    puts lmsg.colorize(:green)
  else
    puts lmsg.colorize(:yellow)
  end

  if !(global_curl_version && local_curl_version)
    puts "Curl not found".colorize(:red)
    puts %Q(
    Linux installation instructions for Curl can be found here: https://www.tecmint.com/install-curl-in-linux/ 
    ).colorize(:red)
  end
  "#{lmsg} #{gmsg}"
end 

def curl_global_response(verbose=false)
  curl_response = `curl --version`
  puts curl_response if verbose
  curl_response 
end

def curl_local_response(verbose=false)
  current_dir = FileUtils.pwd 
  puts current_dir if verbose 
  curl = "#{current_dir}/#{TOOLS_DIR}/curl/linux-amd64/curl"
  # curl_response = `#{curl} --version`
  status = Process.run("#{curl} --version", shell: true, output: curl_response = IO::Memory.new, error: stderr = IO::Memory.new)
  puts curl_response.to_s if verbose
  curl_response.to_s
end

def curl_version(curl_response, verbose=false)
  # example
  # GNU Curl 1.15 built on linux-gnu.
  resp = curl_response.match /curl (([0-9]{1,3}[\.]){1,2}[0-9]{1,3})/
  puts resp if verbose
  "#{resp && resp.not_nil![1]}"
end


