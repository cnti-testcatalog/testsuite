# Test Suite Configuration Usage: cnf-testsuite.yml
### What is the cnf-testsuite.yml and why is it required?:

The cnf-testsuite.yml is used by `cnf_setup` in order to install the CNF to be tested onto an existing K8s cluster. 


The information in the cnf-testsuite.yml is also used for additional configuration of some tests e.g. `allowlist_helm_chart_container_names` is used for exculding containers from the [privileged](https://github.com/cncf/cnf-testsuite/blob/main/src/tasks/workload/security.cr#L196) container test.


### Table of Contents

- [Overview](#Overview-of-all-cnf-testsuite.yml)
- [Generator Quick Start](#Generator-Quick-Start:-cnf-testsuite.yml)
- [Keys and Values](#Keys-and-Values)


### Overview of all cnf-testsuite.yml

The following is a basic working example cnf-testsuite.yml file that can be found in the cnf-testsuite respository: [cnf-testsuite.example.yml](https://github.com/cncf/cnf-testsuite/blob/CNF_TESTSUITE_YML%231357/example-cnfs/coredns/cnf-testsuite.yml)

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


```

### Generator Quick Start: cnf-testsuite.yml 
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

The PATH is also relative to the location of the cnf-testsuite.yml. So if the cnf-testsuite.yml is in the directory `sample-cnfs/sample_coredns/cnf-testsuite.yml` and helm_directory is set to `helm_directory: chart` the test suite would expect to find the chart under [`sample-cnfs/sample_coredns/chart`](https://github.com/cncf/cnf-testsuite/tree/main/sample-cnfs/sample_coredns/chart)

Example Setting:

`helm_directory: coredns`


#### manifest_directory

This is the path to a directory of manifest files for installing the cnf (relative to the location of the cnf-testsuite.yml). This, or [helm_chart](#helm_chart), or [helm_directory](#helm_directory) must be set, but only one **(mutually exclusive)**. This argument is used by cnf_setup in order to deploy the CNF being tested onto an existing K8s cluster.


An example of a manifest directory can be found [here](https://github.com/cncf/cnf-testsuite/tree/main/sample-cnfs/sample_nonroot/manifests).

The PATH is also relative to the location of the cnf-testsuite.yml. So if the cnf-testsuite.yml is in the directory `sample-cnfs/sample_nonroot/cnf-testsuite.yml` and manifest_directory is set to `manifest_directory: manifests` the test suite would expect to find the manifest files under [`sample-cnfs/sample_nonroot/manifests`](https://github.com/cncf/cnf-testsuite/tree/main/sample-cnfs/sample_nonroot/manifests)

Example Setting:

`helm_directory: coredns`



#### release_name

This is the release name of the CNF.(Optional)

When cnf_setup runs this argument is used forfilesystem path version, so the testsuite is able to track what cnfs are currently installed on the cluster. It is also used for the helm release version, when either the [helm_chart](#helm_chart) or [helm_directory](#helm_directory) arguments are in use. Some tests also use this argument for finding and interacting with cluster reasouces for the installed CNF.

This MAY be set. If release_name is not set, a release name will be generated.


Example setting:

`release_name: privileged-coredns`


