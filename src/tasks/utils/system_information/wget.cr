require "file_utils"
require "colorize"
require "totem"

def wget_installation()
  gmsg = "No Global wget version found"
  lmsg = "No Local wget version found"
  gwget = wget_global_response
  Log.debug { gwget }
  
  global_wget_version = wget_version(gwget)
   
  if !global_wget_version.empty?
    gmsg = "Global wget found. Version: #{global_wget_version}"
    stdout_success gmsg
  else
    stdout_warning gmsg
  end

  lwget = wget_local_response
  Log.debug { lwget }
  
  local_wget_version = wget_version(lwget)
   
  if !local_wget_version.empty?
    lmsg = "Local wget found. Version: #{local_wget_version}"
    stdout_success lmsg
  else
    stdout_warning lmsg
  end

  if global_wget_version.empty? && local_wget_version.empty?
    stdout_failure "Wget not found"
    stdout_failure %Q(
    Linux installation instructions for Wget can be found here: https://www.tecmint.com/install-wget-in-linux/ 
    )
  end
  "#{lmsg} #{gmsg}"
end 

def wget_global_response()
  Process.run(
    "wget --version",
    shell: true,
    output: wget_response = IO::Memory.new,
    error: stderr = IO::Memory.new
  )
  Log.debug { wget_response.to_s }
  wget_response.to_s
end

def wget_local_response()
  current_dir = FileUtils.pwd
  Log.debug { current_dir }
  wget = "#{tools_path}/wget/linux-amd64/wget"
  status = Process.run("#{wget} --version", shell: true, output: wget_response = IO::Memory.new, error: stderr = IO::Memory.new)
  Log.info { wget_response.to_s }
  wget_response.to_s
end

def wget_version(wget_response)
  # example
  # GNU Wget 1.15 built on linux-gnu.
  resp = wget_response.match /GNU Wget (([0-9]{1,3}[\.]){1,2}[0-9]{1,3})/
  Log.debug { resp }
  "#{resp && resp.not_nil![1]}"
end


