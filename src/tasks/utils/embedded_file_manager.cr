require "totem"
require "colorize"
require "./cnf_manager.cr"
require "logger"
require "halite"

module EmbeddedFileManager 
  macro reboot_daemon
    REBOOT_DAEMON = File.read("./tools/reboot_daemon/manifest.yml")  
  end
  macro node_failure_values
    NODE_FAILURE_VALUES = File.read("./embedded_files/node_failure_values.yml")
  end
end
