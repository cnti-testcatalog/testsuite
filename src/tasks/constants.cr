require "./utils/system_information/helm.cr"
require "./utils/embedded_file_manager.cr"

CNF_DIR = "cnfs"
CONFIG_FILE = "cnf-testsuite.yml"
TOOLS_DIR = "tools"
BASE_CONFIG = "./config.yml"
OFFLINE_MANIFESTS_PATH = "/tmp/manifests"
PASSED = "passed"
FAILED = "failed"
SKIPPED = "skipped"
NA = "na"
# todo move to helm module
# CHART_YAML = "Chart.yaml"
DEFAULT_POINTSFILENAME = "points_v1.yml"
PRIVILEGED_WHITELIST_CONTAINERS = ["chaos-daemon"]
SONOBUOY_K8S_VERSION = "0.19.0"
KUBESCAPE_VERSION = "1.0.128"
KUBESCAPE_FRAMEWORK_VERSION = "1.0.87"
KIND_VERSION = "0.11.1"
SONOBUOY_OS = "linux"
IGNORED_SECRET_TYPES = ["kubernetes.io/service-account-token", "kubernetes.io/dockercfg", "kubernetes.io/dockerconfigjson", "helm.sh/release.v1"]
EMPTY_JSON = JSON.parse(%({}))
EMPTY_JSON_ARRAY = JSON.parse(%([]))

#Embedded global text variables
EmbeddedFileManager.node_failure_values
EmbeddedFileManager.cri_tools
EmbeddedFileManager.falco_rules
EmbeddedFileManager.reboot_daemon
EmbeddedFileManager.chaos_network_loss
EmbeddedFileManager.chaos_cpu_hog
EmbeddedFileManager.chaos_container_kill
EmbeddedFileManager.points_yml
EmbeddedFileManager.points_yml_write_file
EmbeddedFileManager.enforce_image_tag
EmbeddedFileManager.constraint_template
EmbeddedFileManager.disable_cni

# BinarySingleton = CNFGlobals.new
# class CNFGlobals
#   CNF_DIR = "cnfs"
#   @helm: String?
#   # Get helm directory
#   def helm
#     @helm ||= global_helm_installed? ? "helm" : Helm.local_helm_path
#   end
# end



