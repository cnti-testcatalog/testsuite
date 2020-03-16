require "totem"
require "./sample_utils.cr"
# TODO make constants local or always retrieve from environment variables
# TODO Move constants out
CNF_DIR = "cnfs"
TOOLS_DIR = "tools"
# CONFIG = Totem.from_file "./config.yml"

def check_args(args)
  check_verbose(args)
end

def check_verbose(args)
  if ((args.raw.includes? "verbose") || (args.raw.includes? "v"))
    true
  else 
    false
  end
end

