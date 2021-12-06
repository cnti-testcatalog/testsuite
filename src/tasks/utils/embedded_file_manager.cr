require "totem"
require "colorize"
require "log"
require "halite"

module EmbeddedFileManager 
  macro cluster_tools
    CLUSTER_TOOLS = Base64.decode_string("{{ `cat ./tools/cluster-tools/manifest.yml | base64` }}")
  end
  macro falco_rules
    FALCO_RULES = Base64.decode_string("{{ `cat ./embedded_files/falco_rule.yaml | base64` }}")
  end
  macro node_failure_values
    NODE_FAILED_VALUES = Base64.decode_string("{{ `cat ./embedded_files/node_failure_values.yml  | base64`}}")
  end
  macro reboot_daemon
    REBOOT_DAEMON = Base64.decode_string("{{ `cat ./tools/reboot_daemon/manifest.yml | base64` }}")
  end
  macro chaos_network_loss 
    CHAOS_NETWORK_LOSS = Base64.decode_string("{{ `cat ./embedded_files/chaos_network_loss.yml  | base64`}}")
  end
  macro chaos_cpu_hog 
    CHAOS_CPU_HOG = Base64.decode_string("{{ `cat ./embedded_files/chaos_cpu_hog.yml  | base64`}}")
  end
  macro chaos_container_kill 
    CHAOS_CONTAINER_KILL = Base64.decode_string("{{ `cat ./embedded_files/chaos_container_kill.yml  | base64`}}")
  end
  macro points_yml 
    POINTSFILE = Base64.decode_string("{{ `cat ./embedded_files/points.yml  | base64`}}")
  end
  macro enforce_image_tag 
    ENFORCE_IMAGE_TAG = Base64.decode_string("{{ `cat ./embedded_files/enforce-image-tag.yml  | base64`}}")
  end
  macro constraint_template 
    CONSTRAINT_TEMPLATE = Base64.decode_string("{{ `cat ./embedded_files/constraint_template.yml  | base64`}}")
  end
  macro disable_cni 
    DISABLE_CNI = Base64.decode_string("{{ `cat ./embedded_files/kind-disable-cni.yaml  | base64`}}")
  end
  macro fluentd_values 
    FLUENTD_VALUES = Base64.decode_string("{{ `cat ./embedded_files/fluentd-values.yml  | base64`}}")
  end
  def self.points_yml_write_file
    File.write("points.yml", POINTSFILE)
  end
end
