require "sam"
require "totem"
require "colorize"
require "./utils/cnf_installation/transformer/config_transformer"

desc "Converts an old configuration file to the latest version and saves it to the specified location"
task "transform_config" do |_, args|
  # Ensure both arguments are provided
  if !((args.named.keys.includes? "old_config_path") && (args.named.keys.includes? "new_config_path"))
    stdout_warning "Usage: transform_config old_config_path=OLD_CONFIG_PATH new_config_path=NEW_CONFIG_PATH"
    exit(1)
  end

  old_config_path = args.named["old_config_path"].as(String)
  new_config_path = args.named["new_config_path"].as(String)

  # Check if the old config file exists
  unless File.exists?(old_config_path)
    stdout_failure "Error: The old config file '#{old_config_path}' does not exist."
    exit(1)
  end

  begin
    # Initialize the ConfigTransformer
    transformer = CNFInstall::Config::ConfigTransformer.new(old_config_path)
    transformer.transform

    # Serialize the transformed config to the new file
    transformer.serialize_to_file(new_config_path)

    stdout_success "Configuration successfully transformed and saved to '#{new_config_path}'."
  rescue ex : CNFInstall::Config::UnsupportedConfigVersionError
    stdout_failure ex.message
  rescue ex : Exception
    stdout_failure "Unexpected error: #{ex.class}"
  end
end
