# CNTI Test Catalog CLI Usage Documentation

### Table of Contents

- [Overview](USAGE.md#overview)
- [Syntax and Usage](USAGE.md#syntax-for-running-any-of-the-tests)
- [Common Examples](USAGE.md#common-example-commands)
- [Logging Options](USAGE.md#logging-options)

### Overview

The CNTI Test Catalog can be run in production mode (using an executable) or in developer mode (using [crystal lang directly](INSTALL.md#source-install)). See the [pseudo code documentation](PSEUDO-CODE.md) for examples of how the internals of WIP tests might work.

### Syntax for running any of the tests

```
# Production mode
./cnf-testsuite <testname>

# Developer mode
crystal src/cnf-testsuite.cr <testname>
```

:star: \*Note: All usage commands in this document will use the production (binary executable) syntax unless otherwise stated.

- :heavy_check_mark: indicates implemented into stable release
- :bulb: indicates Proof of Concept
- :memo: indicates To Do
- :x: indicates WARNINGS\*

### Results Output

- :heavy_check_mark: PASSED indicates it meets best practice, positive points given.
- ⏭ SKIPPED indicates the test was skipped (output should provide a reason), no points given.
- :x: FAILED indicates the test failed, negative points given.

---

### Logging Parameters

- **LOG_LEVEL** environment variable: sets minimal log level to display: error (default); info; debug.
- **LOG_PATH** environment variable: if set - all logs would be appended to the file defined by that variable.

---

### Common Example Commands

#### Building the executable

This is the command to build the binary executable if in developer mode or using the source install method ([requires crystal](INSTALL.md#source-install)):

```
crystal build src/cnf-testsuite.cr
```

#### Validating a cnf-testsuite.yml file:

```
./cnf-testsuite validate_config cnf-config=[PATH_TO]/cnf-testsuite.yml
```

#### Installing a cnf:

```
./cnf-testsuite cnf_install cnf-config=./cnf-testsuite.yml
```

##### Skip waiting for resource readiness during installation:
```
./cnf-testsuite cnf_install cnf-config=./cnf-testsuite.yml skip_wait_for_install
```

#### Running all of the platform and workload tests:

```
./cnf-testsuite all cnf-config=<path_to_your_config_file>/cnf-testsuite.yml
```

#### Running all of the tests (including proofs of concepts)

```
./cnf-testsuite all poc cnf-config=<path_to_your_config_file>/cnf-testsuite.yml
```

#### Running all of the workload tests

```
crystal src/cnf-testsuite.cr workload
cnf-config=<path_to_your_config_file>/cnf-testsuite.yml
```

#### Running certification tests

```
./cnf-testsuite cert
./cnf-testsuite cert essential
./cnf-testsuite cert exclude="increase_decrease_capacity single_process_type"
```

#### Running all of the platform or workload tests independently:

##### Run workload only tests:

```
./cnf-testsuite workload
```

##### Run platform only tests (long running):

```
./cnf-testsuite platform
```

#### Get available options and to see all available tests from command line:

```
./cnf-testsuite help
```

#### Clean up the CNTI Test Catalog, the K8s cluster, and upstream projects:

```
./cnf-testsuite uninstall_all
```

---

### Logging Options

#### Update the loglevel from command line:

```
# cmd line
./cnf-testsuite -l debug test
```

#### If in developer mode, make sure to use - - if running from source:

```
crystal src/cnf-testsuite.cr -- -l debug test
```

#### You can also use env var for logging:

```
LOGLEVEL=DEBUG ./cnf-testsuite test
```

:star: Note: When setting log level, the following is the order of precedence:

1. CLI or Command line flag
2. Environment variable
3. CNF-Testsuite [Config file](config.yml)

##### Verbose Option

Also setting the verbose option for many tasks will add extra output to help with debugging

```
./cnf-testsuite test_name verbose
```
#### Environment variables for timeouts:

Timeouts are controlled by these environment variables, set them if default values aren't suitable:
```
CNF_TESTSUITE_GENERIC_OPERATION_TIMEOUT=60
CNF_TESTSUITE_RESOURCE_CREATION_TIMEOUT=120
CNF_TESTSUITE_NODE_READINESS_TIMEOUT=240
CNF_TESTSUITE_POD_READINESS_TIMEOUT=180
CNF_TESTSUITE_LITMUS_CHAOS_TEST_TIMEOUT=1800
CNF_TESTSUITE_NODE_DRAIN_TOTAL_CHAOS_DURATION=90
```

#### Running The Linter

Ameba (https://github.com/crystal-ameba/ameba) is a static code linter for crystal-lang.
To run Ameba, testsuite needs to be installed in developer mode ([Source Install](INSTALL.md#source-install)) and Ameba needs to be installed using source method, which is mentioned in Ameba readme.md:

```
git clone https://github.com/crystal-ameba/ameba && cd ameba
make install
```

After that, follow the usage guidelines from the Ameba repository.

### Usage for categories and single tests

It's located in [TEST_DOCUMENTATION](docs/TEST_DOCUMENTATION.md), Check for needed category or test there.
./cnf-testsuite configuration_lifecycle
```

## [Default namespaces](docs/LIST_OF_TESTS.md#default-namespaces)

##### To run the Default namespace test, you can use the following command:
```
./cnf-testsuite default_namespace
```

<b>Remediation for failing this test:</b> 

Ensure that your CNF is configured to use a Namespace and is not using the default namespace. 

</b>



## [Latest tag](docs/LIST_OF_TESTS.md#latest-tag)

##### To run the Latest tag test, you can use the following command:
```
./cnf-testsuite latest_tag
```

<b>Remediation for failing this test:</b>

When specifying container images, always specify a tag and ensure to use an immutable tag that maps to a specific version of an application Pod. Remove any usage of the `latest` tag, as it is not guaranteed to be always point to the same version of the image.

</b>


## [Require labels](docs/LIST_OF_TESTS.md#require-labels)

##### To run the require labels test, you can use the following command:
```
./cnf-testsuite require_labels
```

<b>Remediation for failing this test:</b> 

Make sure to define `app.kubernetes.io/name` label under metadata for your CNF.

</b>


## [Versioned tag](docs/LIST_OF_TESTS.md#versioned-tag) 

##### To run the versioned tag test, you can use the following command:
```
./cnf-testsuite versioned_tag
```

<b>Remediation for failing this test:</b>

When specifying container images, always specify a tag and ensure to use an immutable tag that maps to a specific version of an application Pod. Remove any usage of the `latest` tag, as it is not guaranteed to be always point to the same version of the image.

</b>


## [nodePort not used](docs/LIST_OF_TESTS.md#nodeport-not-used)

##### To run the nodePort not used test, you can use the following command:
```
./cnf-testsuite nodeport_not_used
```

<b>Remediation for failing this test:</b> 

Review all Helm Charts & Kubernetes Manifest files for the CNF and remove all occurrences of the nostPort field in you configuration. Alternatively, configure a service or use another mechanism for exposing your container.

</b>


## [hostPort not used](docs/LIST_OF_TESTS.md#hostport-not-used)

##### To run the hodePort not used test, you can use the following command:

```
./cnf-testsuite hostport_not_used
```

<b>Remediation for failing this test:</b> 

Review all Helm Charts & Kubernetes Manifest files for the CNF and remove all occurrences of the hostPort field in you configuration. Alternatively, configure a service or use another mechanism for exposing your container.
</b>




## [Hardcoded IP addresses in K8s runtime configuration](docs/LIST_OF_TESTS.md#Hardcoded-ip-addresses-in-k8s-runtime-configuration)

##### To run the Hardcoded IP addresses test, you can use the following command:

```
./cnf-testsuite hardcoded_ip_addresses_in_k8s_runtime_configuration
```

<b>Remediation for failing this test:</b> 

Review all Helm Charts & Kubernetes Manifest files of the CNF and look for any hardcoded usage of ip addresses. If any are found, you will need to use an operator or some other method to abstract the IP management out of your configuration in order to pass this test.   
</b>



## [Secrets used](docs/LIST_OF_TESTS.md#secrets-used)

##### To run the Secrets used test, you can use the following command:
```
./cnf-testsuite secrets_used
```

<b>Rules for the test:</b> The whole test passes if _any_ workload resource in the cnf uses a (non-exempt) secret. If no workload resources use a (non-exempt) secret, the test is skipped.

<b>Remediation for failing this test:</b> 

Remove any sensitive data stored in configmaps, environment variables and instead utilize K8s Secrets for storing such data.  Alternatively, you can use an operator or some other method to abstract hardcoded sensitive data out of your configuration.   
</b>



## [Immutable configmaps](docs/LIST_OF_TESTS.md#immutable-configmap)

##### To run the immutable configmap test, you can use the following command:
```
./cnf-testsuite immutable_configmap
```

<b>Remediation for failing this test:</b> 
Use immutable configmaps for any non-mutable configuration data.
</b>

# 5g Tests

##### To run all 5g tests, you can use the following command:

```
./cnf-testsuite 5g
```

## [smf_upf_core_validator](docs/LIST_OF_TESTS.md#smf_upf_core_validator)

##### To run the 5g core_validator test, you can use the following command:

```
./cnf-testsuite smf_upf_core_validator
```
## [suci_enabled](docs/LIST_OF_TESTS.md#suci_enabled)
##### To run the 5g suci_enabled test, you can use the following command:

```
./cnf-testsuite suci_enabled
```

# RAN Tests

##### To run all RAN tests, you can use the following command:

```
./cnf-testsuite ran
```

## [oran_e2_connection](docs/LIST_OF_TESTS.md#oran_e2_connection)

##### To run the oran e2 connection test, you can use the following command:

```
./cnf-testsuite oran_e2_connection
```



# Platform Tests

##### To run all Platform tests, you can use the following command:

```
./cnf-testsuite platform
```

## [K8s Conformance](docs/LIST_OF_TESTS.md#k8s-conformance)

##### To run the K8s Conformance test, you can use the following command:

```
./cnf-testsuite k8s_conformance
```

<b>Remediation for failing this test:</b> 
Check that [Sonobuoy](https://github.com/vmware-tanzu/sonobuoy) can be successfully run and passes without failure on your platform. Any failures found by Sonobuoy will provide debug and remediation steps required to get your K8s cluster into a conformant state.
</b>


## [ClusterAPI enabled](docs/LIST_OF_TESTS.md#clusterapi-enabled)

##### To run the ClusterAPI enabled test, you can use the following command:

```
./cnf-testsuite clusterapi_enabled
```

<b>Remediation for failing this test:</b> 
Enable ClusterAPI and start using it to manage the provisioning and lifecycle of your Kubernetes clusters.
</b>


##### To run all platform harware and scheduling tests, you can use the following command:
```
./cnf-testsuite  platform:hardware_and_scheduling
```

## [OCI Compliant](docs/LIST_OF_TESTS.md#oci-compliant)

##### To run the OCI Compliant test, you can use the following command:

```
./cnf-testsuite platform:oci_compliant
```
<b>Remediation for failing this test:</b> 

Check if your Kuberentes Platform is using an [OCI Compliant Runtime](https://opencontainers.org/). If you platform is not using an OCI Compliant Runtime, you'll need to switch to a new runtime that is OCI Compliant in order to pass this test.

</b>


##### (PoC) To run All platform resilience tests, you can use the following command:

```
./cnf-testsuite platform:resilience poc
```

## [Worker reboot recovery](docs/LIST_OF_TESTS.md#poc-worker-reboot-recovery)

##### To run the Worker reboot recovery test, you can use the following command:

```
./cnf-testsuite platform:worker_reboot_recovery poc destructive
```
<b>Remediation for failing this test:</b> 

Reboot a worker node in your Kubernetes cluster verify that the node can recover and re-join the cluster in a schedulable state. Workloads should also be rescheduled to the node once it's back online. 
</b>



##### :heavy_check_mark: Run All platform security tests

```
./cnf-testsuite platform:security 
```
## [Cluster admin](docs/LIST_OF_TESTS.md#cluster-admin)
##### To run the Cluster admin test, you can use the following command:

```
./cnf-testsuite platform:cluster_admin
```

<b>Remediation for failing this test:</b> 
You should apply least privilege principle. Make sure cluster admin permissions are granted only when it is absolutely necessary. Don't use subjects with high privileged permissions for daily operations.

See more at [ARMO-C0035](https://bit.ly/C0035_cluster_admin)

</b>


## [Control plane hardening](docs/LIST_OF_TESTS.md#control-plane-hardening)

##### To run the Control plane hardening test, you can use the following command:

```
./cnf-testsuite platform:control_plane_hardening
```

<b>Remediation for failing this test:</b> 

Set the insecure-port flag of the API server to zero.

See more at [ARMO-C0005](https://bit.ly/C0005_Control_Plane)

</b>

```
./cnf-testsuite platform:control_plane_hardening
```

## [Dashboard exposed](docs/LIST_OF_TESTS.md#dashboard-exposed)

##### To run the Dashboard exposed test, you can use the following command:
```
./cnf-testsuite platform:exposed_dashboard
```

<b>Remediation for failing this test: </b>

Update dashboard version to v2.0.1 or above.

</b>


## [Tiller images](docs/LIST_OF_TESTS.md#tiller-images)

##### To run the Tiller images test, you can use the following command:
```
./cnf-testsuite platform:helm_tiller
```

<b>Remediation for failing this test:</b> 
Switch to using Helm v3+ and make sure not to pull any images with name tiller in them
</b>

## [Verify if configmaps are encrypted](docs/LIST_OF_TESTS.md#verify-configmaps-encrypted)

##### To run the Verify if configmaps are encrypted test, you can use the following command:
```
./cnf-testsuite platform:verify_configmaps_encryption
```

<b>Remediation for failing this test:</b> 
Check version of ETCDCTL in etcd pod, it should be v3.+
</b>

