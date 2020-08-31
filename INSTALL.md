Installing the CNF Conformance Test Suite
---
aka CNF Developer Installation Guide

# Prereqs



## Access to a kubernetes Cluster

-  [Access](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/) to a working [Certified K8s](https://cncf.io/ck) cluster via [KUBECONFIG environment variable](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/#set-the-kubeconfig-environment-variable). (See [K8s Getting started guide](https://kubernetes.io/docs/setup/) for options)
-  follow the optional instructions below if you don't already have a k8s cluster setup

### (optional) create a k8s cluster if you don't already have one

#### via kind

follow the [kind install](KIND-INSTALL.md) instructions to setup a cluster in [kind](https://kind.sigs.k8s.io/)

#### or via k8s-infra

- clone the CNF-Testbed

```
cd cnfs/ && git clone https://github.com/cncf/cnf-testbed.git
```

- Clone the K8s-infra repo then Follow the [prerequisites](https://github.com/cncf/cnf-testbed/tree/master/tools#pre-requisites) for [deploying a K8s cluster](https://github.com/cncf/cnf-testbed/tree/master/tools#deploying-a-kubernetes-cluster-using-the-makefile--ci-tools)  for a Packet host.

  * If you already have IP addresses for your provider, and you want to manually install a K8s cluster, you can use k8s-infra to do this.

  ```
  cd tools/ && git clone https://github.com/crosscloudci/k8s-infra.git
  ```

  * #### Follow the [K8s-infra quick start](https://github.com/crosscloudci/k8s-infra/blob/master/README.md#quick-start) for instructions on how to install



## Kubectl installed and configured

- [Kubectl binary is installed](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

- `export KUBECONFIG=$HOME/mycluster.config`

    - Running `kubectl cluster-info` should show a running Kubernetes master in the output



## CNF **must** have a [helm chart](https://helm.sh/)

- To pass all current tests
- To support auto deployment of the CNF from the ([cnf-conformance.yml](https://github.com/cncf/cnf-conformance/blob/master/CNF_CONFORMANCE_YML_USAGE.md)) configuration file





# Installation

We fully support 2 methods of installing the conformance suite:

- Via the latest [**binary** release](#Binary release install instructions)
- and also [from the **source**](#source Install) on github

**Finally:** please make sure to run the `setup` command after finishing your preferred installation method please *or you are going to have a bad time*.



## Binary release install instructions

### Curl install

if that's your style. Unpack the CNF Conformance binary and add it to your PATH and you are good to go!

We support 2 ways.

- Use the curl command to download, install, and export the path simultaneously:

```
source <(curl https://raw.githubusercontent.com/cncf/cnf-conformance/master/curl_install.sh)
```
*or*

- Use the curl command to download and install, but you will have to export the PATH:
```
curl https://raw.githubusercontent.com/cncf/cnf-conformance/master/curl_install.sh | bash
```



### Manual Steps (optional):

(**only** if you do not want to do the curl install)

- Download the latest [binary release](https://github.com/cncf/cnf-conformance/releases) i.e via `wget`
- Make the binary executable (eg. `chmod +x cnf-conformance`)
- Move the downloaded binary to somewhere in your executable PATH (eg. `sudo cp cnf-conformance /usr/local/bin/cnf-conformance`)



### Post Install of binary

once installed please follow the [setup instructions](#Setup) below while taking care to replace

references to `crystal src/cnf-conformance.cr` with `cnf-conformance`

i.e. for setting the sample cnf

```
cnf-conformance sample_coredns_setup
```



#### Install tab completion (optional)

Check out our (experimental) support for tab completion!

NOTE: also compatible with the installation styles from kubectl completion install if you prefer
https://kubernetes.io/docs/tasks/tools/install-kubectl/#enable-kubectl-autocompletion

```
./cnf-conformance completion -l error > test.sh
source test.sh
```



## Source Install

  * Install [crystal-lang](https://crystal-lang.org/install/) version 0.35.1
  * `git clone git@github.com:cncf/cnf-conformance.git`
  * in the project directory install the project's crystal dependencies
  ```
cd cnf-conformance
shards install
  ```

### Post Install

once installed please follow the [setup instructions](#Setup) below



### (optional): Build binary from source

we use the official crystal alpine docker image for builds as you can see in our [.travis.yml](.travis.yml)

```
# this is how we build for production. its static and DOES NOT have any runtime dependencies.

docker pull crystallang/crystal:0.35.1-alpine
docker run --rm -it -v $PWD:/workspace -w /workspace crystallang/crystal:0.35.1-alpine crystal build src/cnf-conformance.cr --release --static --link-flags "-lxml2 -llzma"
```

then you can invoke the conformance suite from the binary i.e.

  ```
./cnf-conformance task_name_to_run
  ```



# Setup

aka configuring the conformance suite for testing a CNF



## (Optional) To set up a *sample cnf* for use with cnf-conformance

Pick this option if you want to quickly kick the tires and see how an already setup cnf works with the conformance suite

```
crystal src/cnf-conformance.cr sample_coredns_setup
```



## Overview (for setting up your own cnf):

- Initialize the test suite by running `crystal src/cnf-conformance.cr setup` (creates cnfs folder and other items)
- Create a Conformance configuration file called `cnf-conformance.yml` under the your CNF folder (eg. `cnfs/my_ipsec_cnf/cnf-conformance.yml`)
  - See example config (See [latest example in repo](https://github.com/cncf/cnf-conformance/blob/master/cnf-conformance.example.yml)):
    - Optionally, copy the example configuration file, [`cnf-conformance-example.yml`](https://github.com/cncf/cnf-conformance/blob/master/cnf-conformance.example.yml), and modify appropriately
- (Optional) Setup your CNF for testing and deploy it to the cluster by running `cnf-conformance cnf_setup cnf-config=path_to_your/cnf_folder`
  - _NOTE: if you do not want to automatically deploy the using the helm chart defined in the configuration then you MUST pass `deploy_with_chart=false` to the `cnf_setup` command._
  - _NOTE: you can pass the path to your cnf-conformance.yml to the 'all' command which will install the CNF for you (see below)_



## Detailed Steps (for setting up your own cnf):

  * Make sure you set your KUBECONFIG
  ```
  export KUBECONFIG=<yourkubeconfig>
  ```
  * Modify the  [`cnf-conformance.yml`](https://github.com/cncf/cnf-conformance/blob/master/cnf-conformance.example.yml)  file settings for your cnfs
  ```
  # In ./<YOURCNFDIRECTORY>/cnf-conformance.yml

helm_directory:
install_script:
deployment_name:
helm_chart:
helm_chart_container_name:
white_list_helm_chart_container_names:
  ```

  * Run the setup tasks to install any prerequisites (useful for setting up sample cnfs)
  ```
  crystal src/cnf-conformance.cr setup
  ```
  * Run the cleanup tasks to remove prerequisites (useful for starting fresh)
  ```
  crystal src/cnf-conformance.cr cleanup
  ```
  * Install your CNF into the cnfs directory, download the helm charts, and download the source code:
  ```
  crystal src/cnf-conformance.cr cnf_setup cnf-config=<path to your cnf config file>
  ```
  * To remove your CNF from the cnfs directory and cluster
  ```
  crystal src/cnf-conformance.cr cnf_cleanup cnf-config=<path to your cnf config file>
  ```



## Get ready to rock and roll!



# Running and checking results for the Conformance testing


**Running all tests**

  ```
cnf-conformance all cnf-config=<path to your config yml>/cnf-conformance.yml
  ```

**Checking the results**

In the console where the test suite runs:
- PASSED or FAILED will be displayed for the tests

A test log file, eg. `cnf-conformance-results-20200401.txt`, will be created which lists PASS or FAIL for every test

**Cleaning up**

Run `cnf-conformance cnf_cleanup cnf-config=<path to your config yml>/cnf-conformance.yml`

_NOTE: Does not handle manually deployed CNFs_

---



# More Example Usage (also see the [complete usage documentation](https://github.com/cncf/cnf-conformance/blob/master/USAGE.md))


```
# Run all ga tests (generally available tests)
crystal src/cnf-conformance.cr all cnf-config=<path to your config yml>/cnf-conformance.yml

# Run all beta and ga tests
crystal src/cnf-conformance.cr all beta

# Run all alpha, beta, and ga tests
crystal src/cnf-conformance.cr all alpha

# Run all wip, alpha, beta, and ga tests
crystal src/cnf-conformance.cr all wip

# Run all tests in the configureation lifecycle category
crystal src/cnf-conformance.cr configuration_lifecycle

# Run all tests in the installability
crystal src/cnf-conformance.cr installability
```



# Development

The CNF Conformance Test Suite is modeled after make, or if you're familiar with Ruby, [rake](https://github.com/ruby/rake). Conformance tests are created via tasks using the Crystal library, [SAM.cr](https://github.com/imdrasil/sam.cr).

To run the automated test suite:

```
crystal spec
```

**Binary build (dev)**

```
# this is how we build while developing. HAS runtime dependencies
crystal build src/cnf-conformance.cr
# you can safely ignore warnings and errors as long as the binary at ./cnf-conformance is generated properly
sha256sum cnf-conformance
# checksum here used for release validation
```
