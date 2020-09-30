require "totem"
require "colorize"
require "./cnf_manager.cr"
require "logger"
require "halite"

module EmbeddedFileManager 
  macro cri_tools
    # CRI_TOOLS = File.read("./tools/cri-tools/manifest.yml")
    CRI_TOOLS = Base64.decode_string("{{ `cat ./tools/cri-tools/manifest.yml | base64` }}")
  end
  macro node_failure_values
    # NODE_FAILURE_VALUES = File.read("./embedded_files/node_failure_values.yml")
    NODE_FAILURE_VALUES = Base64.decode_string("{{ `cat ./embedded_files/node_failure_values.yml  | base64`}}")
  end
  macro reboot_daemon
    REBOOT_DAEMON = Base64.decode_string("{{ `cat ./tools/reboot_daemon/manifest.yml | base64` }}")
  end
end
