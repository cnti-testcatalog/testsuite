# TODO make constants local or always retrieve from environment variables
CNF_DIR = "cnfs"

CONFIG = Totem.from_file "./config.yml"

def check_args (args)
  if args.size > 0 && ((args[0].as(String) == "verbose") || (args[0].as(String) == "v"))
    true
  else 
    false
  end
end
