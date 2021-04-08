# Test Suite Configuration Usage: cnf-conformance.yml

### What is the cnf-conformance.yml and why is it required?:
The cnf-conformance.yml is used by the CNF-Conformance suite to locate a deployed CNF on an existing K8s cluster. If the CNF is not found, it will attempt to deploy the CNF itself according to it's helm chart configuration.

This information is also required for running various tests e.g. The 'container_names' are used for finding the name of the CNF containers in the K8s cluster and is then used to run tests like [increase_capacity](https://github.com/cncf/cnf-conformance/blob/main/src/tasks/scalability.cr#L20) and [decrease_capacity](https://github.com/cncf/cnf-conformance/blob/main/src/tasks/scalability.cr#L42)

### Table of Contents
- [Overview](#Overview-of-all-cnf-conformance.yml)
- [Keys and Values](#Keys-and-Values)
    - [helm_directory](#helm_directory)
    - [git_clone_url](#git_clone_url)
    - [install_script](#install_script)
    - [release_name](#release_name)
    - [deployment_name](#deployment_name)
    - [deployment_label](#deployment_label)
    - [application_deployment_name](#application_deployment_name)
    - [docker_repository](#docker_repository)
    - [helm_repository](#helm_repository)
    - [helm_chart](#helm_chart)
    - [helm_chart_container_name](#helm_chart_container_name)
    - [allowlist_helm_chart_container_names](#allowlist_helm_chart_container_names)
    - [container_names](#container_names)
- [Creating Your Own cnf-conformance.yml](#creating-your-own-cnf-conformanceyml)
- [Setup and Configuration](#Setup-and-Configuration)
- [Quick Setup and Config Reference Steps](#Quick-Setup-and-Config-Reference-Steps)
- [Using a Private Registry](#Using-a-Private-Registry)


### Overview of all cnf-conformance.yml
The following is a basic example cnf-conformance.yml file that can be found in the cnf-conformance respository: [cnf-conformance.example.yml](https://github.com/cncf/cnf-conformance/blob/develop/cnf-conformance.example.yml)
```yaml=
---
#helm_directory: coredns # PATH_TO_CNFS_HELM_CHART ; or
helm_chart: stable/coredns # PUBLISHED_CNFS_HELM_CHART_REPO/NAME
 
git_clone_url: https://github.com/coredns/coredns.git # GIT_REPO_FOR_CNFS_SOURCE_CODE
install_script: cnfs/coredns/Makefile # PATH_TO_CNFS_INSTALL_SCRIPT

release_name: privileged-coredns # DESIRED_HELM_RELEASE_NAME
helm_chart_container_name: privileged-coredns-coredns # POD_SPEC_CONTAINER_NAME
allowlist_helm_chart_container_names: [coredns] # [LIST_OF_CONTAINERS_ALLOWED_TO_RUN_PRIVLIDGED]
container_names: #[LIST_OF_CONTAINERS_NAMES_AND_VERSION_UPGRADE_TAGS]
  - name: sidecar-container1
    rolling_update_test_tag: "1.32.0"
  - name: sidecar-container2
    rolling_update_test_tag: "1.32.0"
```
### Keys and Values

#### helm_directory
This is the path to the helm chart directory (relative to the location of the cnf-conformance.yml). This or [helm_chart](#helm_chart) must be set, but only one **(mutually exclusive)**.

Used for doing static tests on the helm chart code e.g. searching for Hardcoded IPs.

An example of a helm chart source directory can be found [here](https://github.com/helm/charts/tree/master/stable/coredns).

The PATH is also relative to the location of the cnf-conformance.yml. So if the cnf-conformance.yml in the directory ```cnfs/coredns/cnf-conformance.yml``` and helm_directory is set to ```helm_directory: coredns``` the test suite would expect to find the chart under [```cnfs/coredns/coredns```](https://github.com/helm/charts/tree/master/stable/coredns)

Example Setting:

`helm_directory: coredns`

#### git_clone_url
This setting is for the source code of the CNF being tested. (Optional)

The value of git_clone_url is used to clone the source code for the CNF being tested and is then seached through for things like total lines of code, hardcoded ips, etc. 

Example setting:

`git_clone_url: https://github.com/coredns/coredns.git`

*Note: The install of the CNF from a helm chart will always test the helm chart source even if the complete CNF source is not provided.* 


#### install_script
This is the location of additional scripts used to install the CNF being tested. (Optional)

Path to a script used for installing the CNF (relative to the location of the cnf-conformance.yml). This is used by the CNF-Conformance suite to install the CNF if a wrapper around helm is used or helm isn't used at all. If left blank, the CNF will be installed using the helm_chart value.

Example setting:

`install_script: cnfs/coredns/Makefile`

#### release_name
This is the helm release name of the CNF.

If the CNF isn't pre-deployed to the cluster then the test suite will perform the installation and use this name for the helm release / version.

This MAY be set.  If release_name is not set, a release name will be generated. 

Example setting (with no parameters):

`release_name: privileged-coredns`

This is used by the CNF-Conformance suite to interact with the Helm release / installation of the CNF being tested and find meta-data about the CNF.

For example, the [rolling_update](https://github.com/cncf/cnf-conformance/blob/96cee8cefc9a71e62e971f8f4abad56e5db59866/src/tasks/configuration_lifecycle.cr#L156) test uses the helm release_name to fetch the docker image name and tag of the CNF so it can preform a rolling update. [See: rolling_update test](https://github.com/cncf/cnf-conformance/blob/96cee8cefc9a71e62e971f8f4abad56e5db59866/src/tasks/configuration_lifecycle.cr#L179)

For a protected docker registry you must use helm parameters in conjunction with the release name:
```
release_name: coredns --set imageCredentials.registry=https://index.docker.io/v1/ --set imageCredentials.username=$PROTECTED_DOCKERHUB_USERNAME --set imageCredentials.password=$PROTECTED_DOCKERHUB_PASSWORD --set imageCredentials.email=$PROTECTED_DOCKERHUB_EMAIL
```
In the above example, $PROTECTED_DOCKERHUB_USERNAME and $PROTECTED_DOCKERHUB_PASSWORD are environment variables that were previously exported.  The values can then be used as secrets in the helm chart.

#### deployment_name

Example setting: 

`deployment_name: coredns-coredns`

#### deployment_label

Example setting:

`deployment_label: k8s-app`

#### application_deployment_name

Example setting:

`application_deployment_names: [coredns-coredns]`

#### docker_repository

Example setting:

`docker_repository: coredns/coredns`

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

#### helm_chart_container_name

This value is the name of the 'container' defined in the Kubernetes pod spec of the CNF being tested.

This value is used to look up the CNF and determine if it's running in privileged mode (only used within the specs).  The containers in the test are now dynamically determined from the helm chart or manifest files (See: ['privileged' test](https://github.com/cncf/cnf-conformance/blob/c8a2d8f06c5e5976acd1a641350978929a2eee12/src/tasks/security.cr#L32)).

Example setting:

`helm_chart_container_name: privileged-coredns-coredns`

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

This value is used to test the upgradeability of each container image.  The image tag version should be a minor version that will be used in conjunction with the kubnetes rollout feature.

### Creating Your Own cnf-conformance.yml

- Create a Conformance configuration file called `cnf-conformance.yml` under the your CNF folder (eg. `cnfs/my_ipsec_cnf/cnf-conformance.yml`)
  - See example config (See [latest example in repo](https://github.com/cncf/cnf-conformance/blob/main/cnf-conformance.example.yml)):
    - Optionally, copy the example configuration file, [`cnf-conformance-example.yml`](https://github.com/cncf/cnf-conformance/blob/main/cnf-conformance.example.yml), and modify appropriately
- (Optional) Setup your CNF for testing and deploy it to the cluster by running `cnf-conformance cnf_setup cnf-config=path_to_your/cnf_folder`
  - _NOTE: if you do not want to automatically deploy the using the helm chart defined in the configuration then you MUST pass `deploy_with_chart=false` to the `cnf_setup` command._
  - _NOTE: you can pass the path to your cnf-conformance.yml to the 'all' command which will install the CNF for you (see below)_


A configuration file called `cnf-conformance.yml` needs to be created for each CNF you want to test (eg. `cnfs/my_ipsec_cnf/cnf-conformance.yml`).

You can start by copying an example cnf-conformance.yml or copy and paste the below to get started and then filling our the appropriate values:

The [`cnf-conformance.yml`](https://github.com/cncf/cnf-conformance/blob/main/cnf-conformance.example.yml)  file can be used (included in source code or below):
  ```yaml=
---
helm_directory:
install_script:
helm_chart:
helm_chart_container_name:
allowlist_helm_chart_container_names:
container_names:
  - name: <container_name1>
    rolling_update_test_tag: <image-tag-version1>
  - name: <container_name2>
    rolling_update_test_tag: <image-tag-version2>
  ```
  
Below is a fully working example CoreDNS cnf-conformance.yml that tests CoreDNS by installing via helm from a helm repository as a reference:
  
```yaml=
---
helm_directory:
# helm_directory: helm_chart
git_clone_url: 
install_script: 
release_name: coredns
deployment_name: coredns-coredns 
deployment_label: k8s-app 
application_deployment_names: [coredns-coredns]
docker_repository: coredns/coredns
helm_repository:
  name: stable 
  repo_url: https://cncf.gitlab.io/stable
helm_chart: stable/coredns
helm_chart_container_name: coredns
allowlist_helm_chart_container_names: [falco, node-cache, nginx, coredns, calico-node, kube-proxy, nginx-proxy, kube-multus]

container_names: 
  - name: coredns 
    rolling_update_test_tag: "1.8.0"
    rolling_downgrade_test_tag: 1.6.7
    rolling_version_change_test_tag: latest
    rollback_from_tag: latest
```

### Setup and Configuration
Now that you have your own CNF with a cnf-conformance.yml, you should be now be able to setup and run the suite against it.

#### Quick Setup and Config Reference Steps
This assumes you have already followed [INSTALL](INSTALL.md) and or [SOURCE-INSTALL](SOURCE-INSTALL.md) guides.

  * Run the cleanup tasks to remove prerequisites (useful for starting fresh if you've already run the suite previously)
  ```
  ./cnf-conformance cleanup
  ```
 
 * Run the setup tasks to install any prerequisites (useful for setting up sample cnfs and doesn't hurt to run multiple times)

  ```
  ./cnf-conformance setup
  ```
  
 * Setup and configure your CNF by installing your CNF into the cnfs directory, download the helm charts, and download the source code:
  ```
  ./cnf-conformance cnf_setup cnf-config=<path to your cnf config file>
  ```
  
  * To remove your CNF from the cnfs directory and cluster
  ```
  ./cnf-conformance cnf_cleanup cnf-config=<path to your cnf config file>
  ```

### Using a Private Registry
To setup and use a private registry if you are not pulling images from a public repository like Docker Hub, this is the current method to specify a private registry with username and password to pull down images used for the test suite.

You can pass this information directly in the `cnf-conformance.yml` under the `release_name` setting:

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
