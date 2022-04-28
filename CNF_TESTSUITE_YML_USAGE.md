# Test Suite Configuration Usage: cnf-testsuite.yml


#### cnf-testsuite.yml Generator Quick Start
Prereqs: You must have kubernetes cluster, curl, and helm 3.1.1 or greater on your system already.

- Generate a cnf-testsuite.yml based on a helm chart:  `./cnf-testsuite generate_config config-src=stable/coredns output-file=./cnf-testsuite-test.yml`
- Generate a cnf-testsuite.yml based on a helm directory:  `./cnf-testsuite generate_config config-src=<your-helm-directory> output-file=./cnf-testsuite-test.yml`
- Generate a cnf-testsuite.yml based on a directory of manifest files:  `./cnf-testsuite generate_config config-src=<your-manifest-directory> output-file=./cnf-testsuite-test.yml`
- Inspect the cnf-testsuite.yml file for accuracy

### What is the cnf-testsuite.yml and why is it required?:

The cnf-testsuite.yml is used by cnf_setup in order to install the CNF being tested onto an existing K8s cluster.

The information in the cnf-testsuite.yml is then further used for running various tests e.g. The 'container_names' are used for finding the name of the CNF containers in the K8s cluster and is then used to run tests like [increase_capacity](src/tasks/workload/scalability.cr#L20) and [decrease_capacity](src/tasks/workload/scalability.cr#L42)

### Table of Contents

- [Overview](#Overview-of-all-cnf-testsuite.yml)
- [Keys and Values](#Keys-and-Values)
  - [helm_directory](#helm_directory)
  - [release_name](#release_name)
  - [helm_repository](#helm_repository)
  - [helm_chart](#helm_chart)
  - [helm_install_namespace](#helm_install_namespace)
  - [allowlist_helm_chart_container_names](#allowlist_helm_chart_container_names)
  - [container_names](#container_names)
- [Creating Your Own cnf-testsuite.yml](#creating-your-own-cnf-testsuiteyml)
- [Setup and Configuration](#Setup-and-Configuration)
- [Quick Setup and Config Reference Steps](#Quick-Setup-and-Config-Reference-Steps)
- [Using a Private Registry](#Using-a-Private-Registry)

### Overview of all cnf-testsuite.yml

The following is a basic example cnf-testsuite.yml file that can be found in the cnf-testsuite respository: [cnf-testsuite.example.yml](https://github.com/cncf/cnf-testsuite/blob/develop/cnf-testsuite.example.yml)

```yaml=
---
#helm_directory: coredns # PATH_TO_CNFS_HELM_CHART ; or
helm_chart: stable/coredns # PUBLISHED_CNFS_HELM_CHART_REPO/NAME

release_name: privileged-coredns # DESIRED_HELM_RELEASE_NAME
allowlist_helm_chart_container_names: [coredns] # [LIST_OF_CONTAINERS_ALLOWED_TO_RUN_PRIVLIDGED]
container_names: #[LIST_OF_CONTAINERS_NAMES_AND_VERSION_UPGRADE_TAGS]
  - name: sidecar-container1
    rolling_update_test_tag: "1.32.0"
  - name: sidecar-container2
    rolling_update_test_tag: "1.32.0"
```

### Keys and Values

#### helm_directory

This is the path to the helm chart directory (relative to the location of the cnf-testsuite.yml). This or [helm_chart](#helm_chart) must be set, but only one **(mutually exclusive)**.

Used for doing static tests on the helm chart code e.g. searching for Hardcoded IPs.

An example of a helm chart source directory can be found [here](https://github.com/helm/charts/tree/master/stable/coredns).

The PATH is also relative to the location of the cnf-testsuite.yml. So if the cnf-testsuite.yml in the directory `cnfs/coredns/cnf-testsuite.yml` and helm_directory is set to `helm_directory: coredns` the test suite would expect to find the chart under [`cnfs/coredns/coredns`](https://github.com/helm/charts/tree/master/stable/coredns)

Example Setting:

`helm_directory: coredns`

#### release_name

This is the helm release name of the CNF.

If the CNF isn't pre-deployed to the cluster then the test suite will perform the installation and use this name for the helm release / version.

This MAY be set. If release_name is not set, a release name will be generated.

Example setting (with no parameters):

`release_name: privileged-coredns`

This is used by the CNF-Testsuite to interact with the Helm release / installation of the CNF being tested and find meta-data about the CNF.

For example, the [rolling_update](https://github.com/cncf/cnf-testsuite/blob/96cee8cefc9a71e62e971f8f4abad56e5db59866/src/tasks/configuration_lifecycle.cr#L156) test uses the helm release_name to fetch the docker image name and tag of the CNF so it can preform a rolling update. [See: rolling_update test](https://github.com/cncf/cnf-testsuite/blob/96cee8cefc9a71e62e971f8f4abad56e5db59866/src/tasks/configuration_lifecycle.cr#L179)

For a protected docker registry you must use helm parameters in conjunction with the release name:

```
release_name: coredns --set imageCredentials.registry=https://index.docker.io/v1/ --set imageCredentials.username=$PROTECTED_DOCKERHUB_USERNAME --set imageCredentials.password=$PROTECTED_DOCKERHUB_PASSWORD --set imageCredentials.email=$PROTECTED_DOCKERHUB_EMAIL
```

In the above example, $PROTECTED_DOCKERHUB_USERNAME and $PROTECTED_DOCKERHUB_PASSWORD are environment variables that were previously exported. The values can then be used as secrets in the helm chart.

#### helm_repository

This is the URL of your helm repository for your CNF.

Example setting:

```yaml=
helm_repository:
  name: stable
  repo_url: https://cncf.gitlab.io/stable
```

#### helm_chart

The published helm chart name. Like [helm_directory](#helm_directory), this or [helm_directory](#helm_directory) must be set, but not both **(mutually exclusive)**.

Exmple setting:

`helm_chart: stable/coredns`

An example of a publishe helm chart repo/image can be found [here](https://github.com/helm/charts/tree/master/stable/coredns#tldr).

#### helm_install_namespace

When this option is set, the namespace will be passed to the helm command when installing the CNF.

Example setting:

```
helm_install_namespace: "hello-world"
```

#### allowlist_helm_chart_container_names

The values of this key are the names of the 'containers' defined in the Kubernetes pod spec of pods that are allowed to be running in privileged mode. (Optional)

This value is used to allow 'particular' pods to run in privileged mode on the K8s cluster where is CNF being tested is installed.
The reason this is needed is because the Test Suite will check, 'all' pods in the cluster, to see if they're running in privileged mode.

This is done because it's a common cloud-native practice to delegate 'privileged' networking tasks to only a single app e.g Multus, NSM vs making the CNF privileged itself. As a consequence the whitelist can only be used to exempt 'privileged' infrastructure services running as pods e.g NSM, Multus and cannot be used to exempt the CNF being tested.

Example setting:

`allowlist_helm_chart_container_names: [coredns]`

#### container_names

This value is the name of the 'containers' defined in the Kubernetes pod spec of pods and must be set.

Example setting:

```yaml=
container_names: #[LIST_OF_CONTAINERS_NAMES_AND_VERSION_UPGRADE_TAGS]
   - name: <container_name1>
     rolling_update_test_tag: <image-tag-version1>
   - name: <container_name2>
     rolling_update_test_tag: <image-tag-version2>
```

This value is used to test the upgradeability of each container image. The image tag version should be a minor version that will be used in conjunction with the kubnetes rollout feature.

### Creating Your Own cnf-testsuite.yml

- Create a testsuite configuration file called `cnf-testsuite.yml` under the your CNF folder (eg. `cnfs/my_ipsec_cnf/cnf-testsuite.yml`)
  - See example config (See [latest example in repo](https://github.com/cncf/cnf-testsuite/blob/main/cnf-testsuite.example.yml)):
    - Optionally, copy the example configuration file, [`cnf-testsuite-example.yml`](cnf-testsuite.example.yml), and modify appropriately
- (Optional) Setup your CNF for testing and deploy it to the cluster by running `cnf-testsuite cnf_setup cnf-config=path_to_your/cnf_folder`
  - _NOTE: if you do not want to automatically deploy the using the helm chart defined in the configuration then you MUST pass `deploy_with_chart=false` to the `cnf_setup` command._
  - _NOTE: you can pass the path to your cnf-testsuite.yml to the 'all' command which will install the CNF for you (see below)_

A configuration file called `cnf-testsuite.yml` needs to be created for each CNF you want to test (eg. `cnfs/my_ipsec_cnf/cnf-testsuite.yml`).

You can start by copying an example cnf-testsuite.yml or copy and paste the below to get started and then filling our the appropriate values:

The [`cnf-testsuite.yml`](cnf-testsuite.example.yml) file can be used (included in source code or below):

```yaml=
---
helm_directory:
helm_chart:
allowlist_helm_chart_container_names:
container_names:
- name: <container_name1>
  rolling_update_test_tag: <image-tag-version1>
- name: <container_name2>
  rolling_update_test_tag: <image-tag-version2>
```

Below is a fully working example CoreDNS cnf-testsuite.yml that tests CoreDNS by installing via helm from a helm repository as a reference:

```yaml=
---
# Either helm_chart, helm_directory, or manifest_directory is mandatory
# helm_directory: helm_chart
# manifest_directory: manifests
helm_chart: stable/coredns
# Optional
release_name: coredns 
# Optional, if you haven't configured it manually
helm_repository:
  name: stable
  repo_url: https://cncf.gitlab.io/stable
# Optional
allowlist_helm_chart_container_names: [falco, node-cache, nginx, coredns, calico-node, kube-proxy, nginx-proxy, kube-multus]

container_names:
# image name e.g. "coredns" in coredns:1.8.0
  - name: coredns
# test forward compatibility
    rolling_update_test_tag: 1.8.0
# temporary test backwards compatibility
    rolling_downgrade_test_tag: 1.6.7
# will be deprecated
    rolling_version_change_test_tag: latest
# temporary tag, used to rollback to the original tag
    rollback_from_tag: latest
```

### Setup and Configuration

Now that you have your own CNF with a cnf-testsuite.yml, you should be now be able to setup and run the suite against it.

#### Quick Setup and Config Reference Steps

This assumes you have already followed [INSTALL](INSTALL.md) and or [SOURCE-INSTALL](SOURCE-INSTALL.md) guides.

- Run the cleanup tasks to remove prerequisites (useful for starting fresh if you've already run the suite previously)

```
./cnf-testsuite cleanup
```

- Run the setup tasks to install any prerequisites (useful for setting up sample cnfs and doesn't hurt to run multiple times)

```
./cnf-testsuite setup
```

- Setup and configure your CNF by installing your CNF into the cnfs directory, download the helm charts, and download the source code:

```
./cnf-testsuite cnf_setup cnf-config=<path to your cnf config file>
```

- To remove your CNF from the cnfs directory and cluster

```
./cnf-testsuite cnf_cleanup cnf-config=<path to your cnf config file>
```

### Using a Private Registry

To setup and use a private registry if you are not pulling images from a public repository like Docker Hub, this is the current method to specify a private registry with username and password to pull down images used for the test suite.

You can pass this information directly in the `cnf-testsuite.yml` under the `release_name` setting:

Example usage:

```
release_name: release --set imageCredentials.registry=$PROTECTED_REGISTRY_URL --set imageCredentials.username=$PROTECTED_REGISTRY_USERNAME --set imageCredentials.password=$PROTECTED_REGISTRY_PASSWORD --set imageCredentials.email=$PROTECTED_REGISTRY_EMAIL
```

In this example, we are using ENV variables to avoid using usernames and passwords in the actual config files which we highly recommend.

To set the ENV variables, do the following:

```
export PROTECTED_REGISTRY_URL="example.io"
export PROTECTED_REGISTRY_USERNAME=username
export PROTECTED_REGISTRY_PASSWORD=password
export PROTECTED_REGISTRY_EMAIL="email@example.io"
```

In some cases, the email is not necessary. You can leave it blank if not required, eg. `export PROTECTED_REGISTRY_EMAIL=""`

These values are specified in your specific Helm Chart values.yml, e.g.:

```
# Default values for your image
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

imageCredentials:
  registry: example.io
  username: username
  password: password
  email: email@example.io
```
