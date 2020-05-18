require "file_utils"
require "colorize"
require "totem"

def wget_installation(verbose=false)
  gmsg = "No Global wget version found"
  lmsg = "No Local wget version found"
  gwget = wget_global_response
  puts gwget if verbose
  
  global_wget_version = wget_version(gwget, verbose)
   
  if !global_wget_version.empty?
    gmsg = "Global wget found. Version: #{global_wget_version}"
    puts gmsg.colorize(:green)
  else
    puts gmsg.colorize(:yellow)
  end

  lwget = wget_local_response
  puts lwget if verbose
  
  local_wget_version = wget_version(lwget, verbose)
   
  if !local_wget_version.empty?
    lmsg = "Local wget found. Version: #{local_wget_version}"
    puts lmsg.colorize(:green)
  else
    puts lmsg.colorize(:yellow)
  end

  if !(global_wget_version && local_wget_version)
    puts "Wget not found".colorize(:red)
    puts %Q(
    Linux installation instructions for Wget can be found here: https://www.tecmint.com/install-wget-in-linux/ 
    ).colorize(:red)
  end
  "#{lmsg} #{gmsg}"
end 

def wget_global_response(verbose=false)
  wget_response = `wget --version`
  puts wget_response if verbose
  wget_response 
end

def wget_local_response(verbose=false)
  current_dir = FileUtils.pwd 
  puts current_dir if verbose 
  wget = "#{current_dir}/#{TOOLS_DIR}/wget/linux-amd64/wget"
  # wget_response = `#{wget} --version`
  status = Process.run("#{wget} --version", shell: true, output: wget_response = IO::Memory.new, error: stderr = IO::Memory.new)
  puts wget_response.to_s if verbose
  wget_response.to_s
end

def wget_version(wget_response, verbose=false)
  # example
  # GNU Wget 1.15 built on linux-gnu.
  resp = wget_response.match /GNU Wget (([0-9]{1,3}[\.]){1,2}[0-9]{1,3})/
  puts resp if verbose
  "#{resp && resp.not_nil![1]}"
end


