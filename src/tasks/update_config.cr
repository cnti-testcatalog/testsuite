require "sam"
require "totem"
require "colorize"
require "./utils/cnf_installation/config_updater/config_updater"
require "./utils/cnf_installation/config"

desc "Updates an old configuration file to the latest version and saves it to the specified location"
task "update_config" do |_, args|
  # Ensure both arguments are provided
  if !((args.named.keys.includes? "input_config") && (args.named.keys.includes? "output_config"))
    stdout_warning "Usage: update_config input_config=OLD_CONFIG_PATH output_config=NEW_CONFIG_PATH"
    exit(0)
  end

  input_config = args.named["input_config"].as(String)
  output_config = args.named["output_config"].as(String)

  # Check if the input config file exists
  unless File.exists?(input_config)
    stdout_failure "The input config file '#{input_config}' does not exist."
    exit(1)
  end

  begin
    raw_input_config = File.read(input_config)

    # Verify that config is not the latest version
    if CNFInstall::Config.config_version_is_latest?(raw_input_config)
      stdout_warning "Input config is the latest version."
      exit(0)
    end

    # Initialize the ConfigUpdater
    updater = CNFInstall::Config::ConfigUpdater.new(raw_input_config)
    updater.transform

    # Serialize the updated config to the new file
    updater.serialize_to_file(output_config)

    stdout_success "Configuration successfully updated and saved to '#{output_config}'."
  rescue ex : CNFInstall::Config::UnsupportedConfigVersionError
    stdout_failure ex.message
    exit(1)
  end
end
