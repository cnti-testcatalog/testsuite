# TODO make constants local or always retrieve from environment variables
# TODO Move constants out
CNF_DIR = "cnfs"
TOOLS_DIR = "tools"
# CONFIG = Totem.from_file "./config.yml"

def check_args (args)
  if args.size > 0 && ((args[0].as(String) == "verbose") || (args[0].as(String) == "v"))
    true
  else 
    false
  end
end

def check_verbose (args)
  if ((args.raw.includes? "verbose") || (args.raw.includes? "v"))
    true
  else 
    false
  end
end

def cnf_conformance_yml
  cnf_conformance = `find cnfs/* -name "cnf-conformance.yml"`.split("\n")[0]
  if cnf_conformance.empty?
    raise "No cnf_conformance.yml found! Did you run the setup task?"
  end
  Totem.from_file "./#{cnf_conformance}"
end
