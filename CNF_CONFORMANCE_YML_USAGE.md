# 2020-04-15 - WIP documenting the cnf-conformance.yml


### What is the cnf-conformance.yml and why is it required?:
The cnf-conformance.yml is used by the CNF-Conformance suite to locate a deployed CNF on an existing K8s cluster or get enough information about the CNF and it's helm chart that will allow the test suite to deploy the CNF itself.

This information is also required for running various tests e.g. The 'deployment_name' is used for finding the name of the CNF deployment in the K8s cluster and is then used to run tests like [increase_capacity](https://github.com/cncf/cnf-conformance/blob/master/src/tasks/scalability.cr#L20) and [decrease_capacity](https://github.com/cncf/cnf-conformance/blob/master/src/tasks/scalability.cr#L42)




### All cnf-conformance.yml keys/values
###### [cnf-conformance.example.yml](https://github.com/cncf/cnf-conformance/blob/develop/cnf-conformance.example.yml)
```yaml=
---
#helm_directory: coredns # PATH_TO_CNFS_HELM_CHART ; or
helm_chart_repo: stable/coredns # PUBLISHED_CNFS_HELM_CHART_REPO/NAME
 
git_clone_url: https://github.com/coredns/coredns.git # GIT_REPO_FOR_CNFS_SOURCE_CODE
install_script: cnfs/coredns/Makefile # PATH_TO_CNFS_INSTALL_SCRIPT

release_name: privileged-coredns # DESIRED_HELM_RELEASE_NAME
deployment_name: privileged-coredns-coredns  # CNFS_KUBERNETES_DEPLOYMENT_NAME
application_deployment_names: N/A
helm_chart_container_name: privileged-coredns-coredns # POD_SPEC_CONTAINER_NAME
white_list_helm_chart_container_names: [coredns] # [LIST_OF_CONTAINERS_ALLOWED_TO_RUN_PRIVLIDGED]
```

#### helm_directory: path to the helm chart directory (relative to the location of the cnf-conformance.yml)
MUST BE SET: (Mutually exclusive with helm_chart).
Used for doing static tests on the helm chart code e.g. searching for Hardcoded IPs.

An example of a helm chart source directory can be found [here](https://github.com/helm/charts/tree/master/stable/coredns).

The Path is also relative to the location of the cnf-conformance.yml. So if the cnf-conformance.yml in the directory ```charts/stable/cnf-conformance.yml``` and helm_directory is set to ```helm_directory: coredns``` the test suite would expect to find the chart under [```charts/stable/coredns```](https://github.com/helm/charts/tree/master/stable/coredns)

#### helm_chart: Published helm chart repo and chart name.
MUST BE SET: (Mutually exclusive with helm_directory).
Used for doing static tests on the helm chart code e.g. searching for Hardcoded IPs.

An example of a publishe helm chart repo/image can be found [here](https://github.com/helm/charts/tree/master/stable/coredns#tldr).

#### git_clone_url: Git-repo for the source code of the CNF being tested. (Optional)
The value of git_clone_url is used to clone the source code for the CNF being tested and is then seached through for things like total lines of code, hardcoded ips, etc. Note: The install of the CNF from a helm chart will always test the helm chart source even if the complete CNF source is not provided. 


#### install_script: Location of additional scripts used to install the CNF being tested. (Optional)

Path to script used for installing the CNF (relative to the location of the cnf-conformance.yml). This is used by the CNF-Conformance suite to install the CNF if a wrapper around helm is used or helm isn't used at all. If this is blank, the CNF will be installed using the helm_chart value.

#### release_name: The helm release name of the CNF; if the CNF isn't pre-deployed to the cluster then the test suite will perform the installation and use this name for the helm release / version.
This MUST be set.
This is used by the CNF-Conformance suite to interact with the Helm release / installation of the CNF being tested and find meta-data about the CNF. For example the [rolling_update](https://github.com/cncf/cnf-conformance/blob/96cee8cefc9a71e62e971f8f4abad56e5db59866/src/tasks/configuration_lifecycle.cr#L156) test uses the helm release_name to fetch the docker image name and tag of the CNF so it can preform a rolling update. [See: rolling_update test](https://github.com/cncf/cnf-conformance/blob/96cee8cefc9a71e62e971f8f4abad56e5db59866/src/tasks/configuration_lifecycle.cr#L179)

#### deployment_name: The Kubernetes deployment name of the CNF after it has been installed to the K8s cluster.
This MUST be set.

#### application_deployment_names: This value isn't currently used by any tests.
This MAY be set.


#### helm_chart_container_name: This value is the name of the 'container' defined in the Kubernetes pod spec of the CNF being tested. (See: [for example](https://github.com/helm/charts/blob/master/stable/coredns/templates/deployment.yaml#L72)) 
This MUST be set.
This value is used to look up the CNF and determine if it's running in privileged mode (See: ['privileged' test](https://github.com/cncf/cnf-conformance/blob/c8a2d8f06c5e5976acd1a641350978929a2eee12/src/tasks/security.cr#L32)).

#### white_list_helm_chart_container_names: This value is the name of the 'container' defined in the Kubernetes pod spec of pods that are allowed to be running in privileged mode. (Optional)
This value is used to allow 'particular' pods to run in privileged mode on the K8s cluster where is CNF being tested is installed.
The reason this is needed is because the Test Suite will check, 'all' pods in the cluster, to see if they're running in privileged mode.

This is done because it's a common cloud-native practice to delegate 'privileged' networking tasks to only a single app e.g Multus, NSM vs making the CNF privileged itself. As a consequence the whitelist can only be used to exempt 'privileged' infrastructre services running as pods e.g NSM, Multus and cannot be used to exempt the CNF being tested.
