require "totem"
require "./sample_utils.cr"
# TODO make constants local or always retrieve from environment variables
# TODO Move constants out
CNF_DIR = "cnfs"
TOOLS_DIR = "tools"

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

def toggle(toggle_name)
  toggle_on = false
  if File.exists?("./config.yml")
    config = Totem.from_file "./config.yml"
    if config["toggles"].as_a?
      feature_flag = config["toggles"].as_a.find do |x| 
        x["name"] == toggle_name
      end
      toggle_on = feature_flag["toggle_on"].as_bool if feature_flag
    end
  else
    toggle_on = false
  end
  toggle_on
end

