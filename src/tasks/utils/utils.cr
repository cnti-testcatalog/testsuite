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

## check feature level e.g. --beta
## if no feature level then feature level = ga
def check_feature_level(args)
  case args.raw
  when .includes? "alpha"
    "alpha"
  when .includes? "beta"
    "beta"
  when .includes? "wip"
    "wip"
  else
    "ga"
  end
end

# cncf/cnf-conformance/issues/106
# Requesting beta tests to run will both beta and ga flagged tests
# Requesting alpha tests will run alpha, beta, and ga flagged tests
# Requesting wip tests will run wip, poc, beta, and ga flagged tests

# if the beta flag is not true but the alpha is true, then beta tests should be run
def check_beta
  toggle("beta") || check_alpha
end

# if the beta flag is not true but the alpha is true, then beta tests should be run
def check_beta(args)
  toggle("beta") || check_feature_level(args) == "beta" || check_alpha(args)
end

# if the alpha flag is not true but the wip is true, then alpha tests should be run
def check_alpha
  toggle("alpha") || check_wip
end

# if the alpha flag is not true but the wip is true, then alpha tests should be run
def check_alpha(args)
  toggle("alpha") || check_feature_level(args) == "alpha" || check_wip(args)
end

def check_wip
  toggle("wip")
end

def check_wip(args)
  toggle("wip") || check_feature_level(args) == "wip"
end
