require "./utils/embedded_file_manager.cr"

ESSENTIAL_PASSED_THRESHOLD = 15
CNF_DIR = "cnfs"
CONFIG_FILE = "cnf-testsuite.yml"
BASE_CONFIG = "./config.yml"
PASSED = "passed"
FAILED = "failed"
SKIPPED = "skipped"
NA = "na"
ERROR = "error"
# todo move to helm module
# CHART_YAML = "Chart.yaml"
DEFAULT_POINTSFILENAME = "points_v1.yml"
SONOBUOY_K8S_VERSION = "0.56.14"
KUBESCAPE_VERSION = "3.0.8"
KUBESCAPE_FRAMEWORK_VERSION = "1.0.316"
KIND_VERSION = "0.17.0"
SONOBUOY_OS = "linux"
IGNORED_SECRET_TYPES = ["kubernetes.io/service-account-token", "kubernetes.io/dockercfg", "kubernetes.io/dockerconfigjson", "helm.sh/release.v1"]
EMPTY_JSON = JSON.parse(%({}))
EMPTY_JSON_ARRAY = JSON.parse(%([]))
SPECIALIZED_INIT_SYSTEMS = ["tini", "dumb-init", "s6-svscan"]
ROLLING_VERSION_CHANGE_TEST_NAMES = ["rolling_update", "rolling_downgrade", "rolling_version_change"]

TESTSUITE_NAMESPACE = "cnf-testsuite"
DEFAULT_CNF_NAMESPACE = "cnf-default"

#Embedded global text variables
EmbeddedFileManager.node_failure_values
EmbeddedFileManager.reboot_daemon
EmbeddedFileManager.chaos_network_loss
EmbeddedFileManager.chaos_cpu_hog
EmbeddedFileManager.chaos_container_kill
EmbeddedFileManager.points_yml
EmbeddedFileManager.points_yml_write_file
EmbeddedFileManager.enforce_image_tag
EmbeddedFileManager.constraint_template
EmbeddedFileManager.disable_cni
EmbeddedFileManager.fluentd_values
EmbeddedFileManager.fluentbit_values
EmbeddedFileManager.fluentd_bitnami_values
EmbeddedFileManager.ueransim_helmconfig

EXCLUDE_NAMESPACES = [
  "kube-system",
  "kube-public",
  "kube-node-lease",
  "local-path-storage",
  "litmus",
  TESTSUITE_NAMESPACE
]
