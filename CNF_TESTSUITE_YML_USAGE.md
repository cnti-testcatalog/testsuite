# Test Suite Configuration Usage: cnf-testsuite.yml
### What is the cnf-testsuite.yml and why is it required?:

The cnf-testsuite.yml is used by `cnf_setup` in order to install the CNF to be tested onto an existing K8s cluster. 


The information in the cnf-testsuite.yml is also used for additional configuration of some tests e.g. `allowlist_helm_chart_container_names` is used for exculding containers from the [privileged](https://github.com/cnti-testcatalog/testsuite/blob/main/src/tasks/workload/security.cr#L196) container test.


### Table of Contents

- [Overview](#Overview-of-all-cnf-testsuite.yml)
- [Generator Quick Start](#Generator-Quick-Start)
- [Keys and Values](#Keys-and-Values)


### Overview of all cnf-testsuite.yml

The following is a basic working example cnf-testsuite.yml file that can be found in the cnf-testsuite respository: [cnf-testsuite.example.yml](https://github.com/cnti-testcatalog/testsuite/blob/CNF_TESTSUITE_YML%231357/example-cnfs/coredns/cnf-testsuite.yml)

```yaml=
---
allowlist_helm_chart_container_names: [] # [LIST_OF_CONTAINERS_ALLOWED_TO_RUN_PRIVLIDGED]
helm_chart: stable/coredns # PUBLISHED_CNFS_HELM_CHART_REPO/NAME ; or
helm_repository: # CONFIGURATION OF HELM REPO - ONLY NEEDED WHEN USING helm_chart 
  name: stable # HELM_CHART_REPOSITORY_NAME
  repo_url: https://cncf.gitlab.io/stable # HELM_CHART_REPOSITORY_URL
#helm_directory: coredns # PATH_TO_CNFS_HELM_CHART ; or
#manifest_directory: coredns # PATH_TO_DIRECTORY_OF_CNFS_MANIFEST_FILES ; or
release_name: coredns # DESIRED_HELM_RELEASE_NAME
helm_values: --versions 16.2.0 --set persistence.enabled=false
helm_install_namespace: cnfspace # Installs the CNF to it's own namespace and not in the default namespace


```

### Generator Quick Start 
You can quickly generate your own cnf-testsuite.yml dynamically for a CNF by running one of the below commands.
Prereqs: You must have kubernetes cluster, curl, and helm 3.1.1 or greater on your system already.

- Generate a cnf-testsuite.yml based on a helm chart:  `./cnf-testsuite generate_config config-src=stable/coredns output-file=./cnf-testsuite.yml`
- Generate a cnf-testsuite.yml based on a helm directory:  `./cnf-testsuite generate_config config-src=<your-helm-directory> output-file=./cnf-testsuite.yml`
- Generate a cnf-testsuite.yml based on a directory of manifest files:  `./cnf-testsuite generate_config config-src=<your-manifest-directory> output-file=./cnf-testsuite.yml`
- Inspect the cnf-testsuite.yml file for accuracy

### Keys and Values

#### allowlist_helm_chart_container_names

The values of this key are the names of the 'containers' defined in the Kubernetes pod spec of pods that are allowed to be running in privileged mode. (Optional)

This value is used to allow 'particular' pods to run in privileged mode on the K8s cluster where is CNF being tested is installed.

The reason this is needed is because the Test Suite will check, 'all' pods in the cluster, to see if they're running in privileged mode.

This is done because it's a common cloud-native practice to delegate 'privileged' networking tasks to only a single app e.g Multus, NSM vs making the CNF privileged itself. As a consequence the allowlist can only be used to exempt 'privileged' infrastructure services running as pods e.g NSM, Multus and cannot be used to exempt the CNF being tested.

Example setting:

`allowlist_helm_chart_container_names: [coredns]`



#### helm_chart

The published helm repository & chart name. This, or [helm_directory](#helm_directory), or [manifest_directory](#manifest_directory) must be set, but only one **(mutually exclusive)**. This argument is used by cnf_setup in order to install the helm chart for the CNF being tested onto an existing K8s cluster.


Exmple setting:

`helm_chart: stable/coredns`

An example of a publishe helm chart repo/image can be found [here](https://github.com/helm/charts/tree/master/stable/coredns#tldr).

#### helm_repository

This is used for configuring the name and URL of the helm chart repository being used for installing the cnf. (Optional) 

This agument is used in conjunction with the above argument, [helm_chart](#helm_chart). e.g. if [helm_chart](#helm_chart) is set to `stable/coredns`, the stable component refers to a local helm repository that has already been configured, you can list your local helm repositories by running `helm repo list`. If you don't want to use an already configured repo, you can define it by using the [helm_repository](#helm_repository) argument, and cnf_setup will configure and manage the local helm repository for you.

Example setting:

```yaml=
helm_repository:
  name: stable
  repo_url: https://cncf.gitlab.io/stable
```


#### helm_directory

This is the path to the helm chart directory (relative to the location of the cnf-testsuite.yml). This, or [helm_chart](#helm_chart), or [manifest_directory](#manifest_directory) must be set, but only one **(mutually exclusive)**. This argument is used by cnf_setup in order to install the helm chart for the CNF being tested onto an existing K8s cluster.

 
An example of a helm directory can be found [here](https://github.com/helm/charts/tree/master/stable/coredns).

The PATH is also relative to the location of the cnf-testsuite.yml. So if the cnf-testsuite.yml is in the directory `sample-cnfs/sample_coredns/cnf-testsuite.yml` and helm_directory is set to `helm_directory: chart` the test suite would expect to find the chart under [`sample-cnfs/sample_coredns/chart`](https://github.com/cnti-testcatalog/testsuite/tree/main/sample-cnfs/sample_coredns/chart)

Example Setting:

`helm_directory: coredns`


#### helm_install_namespace

This sets the namespace that helm will use to install the CNF to. This is to conform to the best practice of not installing your CNF to the `default` namespace on your cluster. You can learn more about this practice [here](./docs/TEST_DOCUMENTATION.md#default-namespaces). This is an optional setting but highly recommended as installing your CNF to use the `default` namespace will result with failed tests.

You can learn more about kubernetes namespaces [here](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

Example Setting:

`helm_install_namespace: cnfspace`


#### manifest_directory

This is the path to a directory of manifest files for installing the cnf (relative to the location of the cnf-testsuite.yml). This, or [helm_chart](#helm_chart), or [helm_directory](#helm_directory) must be set, but only one **(mutually exclusive)**. This argument is used by cnf_setup in order to deploy the CNF being tested onto an existing K8s cluster.


An example of a manifest directory can be found [here](https://github.com/cnti-testcatalog/testsuite/tree/main/sample-cnfs/sample_nonroot/manifests).

The PATH is also relative to the location of the cnf-testsuite.yml. So if the cnf-testsuite.yml is in the directory `sample-cnfs/sample_nonroot/cnf-testsuite.yml` and manifest_directory is set to `manifest_directory: manifests` the test suite would expect to find the manifest files under [`sample-cnfs/sample_nonroot/manifests`](https://github.com/cnti-testcatalog/testsuite/tree/main/sample-cnfs/sample_nonroot/manifests)

Example Setting:

`helm_directory: coredns`



#### release_name

This is the release name of the CNF. (Optional)

When cnf_setup runs this argument is used forfilesystem path version, so the testsuite is able to track what cnfs are currently installed on the cluster. It is also used for the helm release version, when either the [helm_chart](#helm_chart) or [helm_directory](#helm_directory) arguments are in use. Some tests also use this argument for finding and interacting with cluster reasouces for the installed CNF.

This MAY be set. If release_name is not set, a release name will be generated.

Example setting:

`release_name: privileged-coredns`

#### helm_values

This is for any helm argument. (Optional)

When installing from helm, there are helm arguments (e.g. --version 1234 ) and helm values (e.g. --set myvalue=42).  Both of these will be passed on to the underlying helm installation command when it is run.  


Example setting:

`--set myvalue=42`


#### `image_registry_fqdns`

When using a private registry hosted on the cluster, the image references in the CNF's helm chart may refer to the registry host with the Kubernetes service name alone. The CNF Testsuite runs a docker daemon in a separate `cnf-testsuite` namespace on the Kubernetes cluster. So it is required for the testsuite to be aware of the FQDN of the service, along with the port.

Use this option to configure FQDNs of image registries for the testsuite to access.

If the CNF's helm charts use the image url `foobar:5000/hello:latest`, then please use the configuration in below in `cnf-testsuite.yml` to provide the FQDN mapping for the image registry.

```yaml
image_registry_fqdns:
    "foobar:5000": "foobar.default.svc.cluster.local:5000"
```

> *The above example assumes that the `foobar` registry service is running on the `default` namespace.*

#### `docker_insecure_registries`

The docker client expects the image registries to be using an HTTPS API endpoint. This option is used to configure insecure registries that the docker client should be allowed to access.

Please use this option to configure Docker to use HTTP to access the registry API.

For an image registry service named `foobar`, running in `default` namespace, on port `5000`, the following would be the expected configuration.

```yaml
docker_insecure_registries: ["foobar.default.svc.cluster.local:5000"]
```
### RAN configuration

#### `ric_label`

The ran tests expect a ric to be configured under the ric_label.  The entry must be the k8s label which is most likely a full key/value identification.

For a ric named `flexrric`, under the label key `app.kubernetes.io/name` the following would be the expected configuration.

```yaml
ric_label:  app.kubernetes.io/name=flexric
```
### Open5gs and UERANSIM configuration

#### mmc

Mobile Country Code. This identifies the country of the mobile subscriber. In this case, '999' is a test code.

```yaml
dmmc: '999
```
#### mnc

Mobile Network Code. This identifies the mobile network within the country specified by the MCC. '70' is a test code.
```yaml
mnc: '70'
```

#### sst

Single-NEC Single Radio Voice Call Continuity. This value indicates the type of services a Slice/Session should support.

```yaml
sst: 1
```

#### sd

Slice Differentiator. This is used to differentiate between different slices within the same SST.

```yaml
sd: '0x111111'
```

#### tac

Tracking Area Code. This is used for paging procedures and to manage mobility between eNBs in LTE.

```yaml
tac: '0001'
```
#### protectionScheme

The type of security protocol being used.

```yaml
protectionScheme: 1
```
#### publicKey

This is the public key used in asymmetric encryption.

```yaml
publicKey: 0ac95ceeb93308df01be82ff9994d8330e38804ece1700ee4b972d8028796275
```

#### publicKeyId

Identifier for the public key.

```yaml
publicKeyId: 1:
```

#### routingIndicator

This is used to route messages in the network.

```yaml
routingIndicator: '0000'
```

#### enabled

Indicates whether the network is currently enabled or not.

```yaml
enabled: true
```

#### count

Used in UERANSIM to specify the number of entities (like User Equipment or UEs) to be simulated.

```yaml
count: 1
```

#### initialMSISDN

This MSISDN is a unique number that identifies a subscription in a GSM or a UMTS mobile network.

```yaml
initialMSISDN: '0000000001'
```

#### key

Cryptographic key used in the network.

```yaml
key: 465B5CE8B199B49FAA5F0A2EE238A6BC:
```

#### op

The operator variant algorithm configuration field. Used in conjunction with the key for security purposes.

```yaml
op: E8ED289DEBA952E4283B54E88E6183CA
```

#### opType

Indicates that the operator variant algorithm is in use.

```yaml
opType: OPC
```

#### type

The type of IP addresses being used in the network.

```yaml
type: 'IPv4'
```

#### apn

Access Point Name. This is the name of a gateway between a GPRS, 3G or 4G mobile network and another computer network, frequently the public internet.

```yaml
apn: 'internet'
```

#### emergency:

Indicates whether this is an emergency APN.

```yaml
emergency: false
```

