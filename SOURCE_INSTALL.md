Installing the CNF Conformance Test Suite from Source
---
### Overview
This INSTALL guide will detail the minimum requirements needed for cnf-conformance to install from source.

### Table of Contents
* [**Pre-Requisites**](#Pre-Requisites)
* [**Installation**](#Installation)
* [**Setup**](#Setup)
* [**Configuration**](#Configuration)
* [**Running cnf-conformance for the first time**](#Running-cnf-conformance-for-the-first-time)

### Pre-Requisites

#### Requirements
* **kubernetes cluster** *(Working k8s cluster, see [supported k8s and installation details](#Details-on-supported-k8s-clusters-and-installation) on installation.*
* **kubectl** *(run commands against k8 clusters, see [installing kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for more details.*
* **curl**
* **helm 3.1.1** *or newer* *(cnf-conformance installs if not found locally)*
* **git** *(used to check out code from github)*
* **crystal-lang** version 0.35.1 *(to compile the source and build the binary, see [crystal installation](https://crystal-lang.org/install/)) for more information.*
* **shards** ([dependency manager](https://github.com/crystal-lang/shards) for crystal-lang)
##### Optional Requirement
* **docker** (for building from crystal alpine image)

#### Details on supported k8s clusters and installation:
<details><summary>Click here to drop down details</summary>

<p>

##### Supported k8s Clusters
- [Access](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/) to a working [Certified K8s](https://cncf.io/ck) cluster via [KUBECONFIG environment variable](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/#set-the-kubeconfig-environment-variable). (See [K8s Getting started guide](https://kubernetes.io/docs/setup/) for options)
-  Follow the optional instructions below if you don't already have a k8s cluster setup

##### Kind

- Follow the [kind install](KIND-INSTALL.md) instructions to setup a cluster in [kind](https://kind.sigs.k8s.io/)

##### k8s-infra

- You can clone the CNF-Testbed project if you have an account at Equinix Metal (formerly Packet.net). Get the code by running the following:

```
git clone https://github.com/cncf/cnf-testbed.git
```

- Clone the K8s-infra repo then Follow the [prerequisites](https://github.com/cncf/cnf-testbed/tree/master/tools#pre-requisites) for [deploying a K8s cluster](https://github.com/cncf/cnf-testbed/tree/master/tools#deploying-a-kubernetes-cluster-using-the-makefile--ci-tools) for a Equinix Metal host.
- If you already have IP addresses for your provider, and you want to manually install a K8s cluster, you can use k8s-infra to do this within your cnf-testbed repo clone.

```
cd tools/ && git clone https://github.com/crosscloudci/k8s-infra.git
```

- Now follow the [K8s-infra quick start](https://github.com/crosscloudci/k8s-infra/blob/master/README.md#quick-start) for instructions on how to install.

</p>
</details>



### Installation
We can assume you have access to a working kubernetes cluster. We recommend only running the cnf-conformance suite on dev or test clusters.

- Verify your KUBECONFIG points to your correct k8s cluster:
  ```
  echo $KUBECONFIG
  ```
  If there's no output or it's pointed to the wrong config, run the export to the correct config:
  ```
  export KUBECONFIG=yourkubeconfig
  ```
- Verify your cluster is accessible with kubectl (this command should provide information about your kubernetes cluster):
  ```
  kubectl cluster-info
  ```
- You'll need cystal-lang v0.35.1 or higher installed. You can follow their [install instructions](https://crystal-lang.org/install/) for their many different methods.
- cnf-conformance needs helm-3.1.1 or greater. You can install helm by checking their [installation methods](https://helm.sh/docs/helm/helm_install/) but you can also skip this as cnf-conformance will install if it's not found.
- Checkout the source code with git:
  ```
  git clone git@github.com:cncf/cnf-conformance.git
  ```
- Change directory into the source:
  ```
  cd cnf-conformance
  ```
- Now we need to run shards to pull down requirements needed to build and compile cnf-conformance:
  ```
  shards install
  ```
- Now build a cnf-conformance binary (this method will have runtime dependencies but should not pose any issues):
  ```
  crystal build src/cnf-conformance.cr
  ```
  This should create an executable `cnf-conformance` binary in your source checkout.
  
<details><summary>(Optional) Build cnf-conformance using Docker  Alpine Image</summary>
<p>

We use the official crystal alpine docker image for builds; seen in [actions.yml](.github/workflows/actions.yml)

*This build method is static and DOES NOT have any runtime dependencies.*

- To build using docker crystal alpine image (great if you don't have crystal installed)

```
docker pull crystallang/crystal:0.35.1-alpine
docker run --rm -it -v $PWD:/workspace -w /workspace crystallang/crystal:0.35.1-alpine crystal build src/cnf-conformance.cr --release --static --link-flags "-lxml2 -llzma"
```
</p>
</details>

<details> <summary>(Optional) Install Tab Completion</summary>

<p>
NOTE: Also compatible with the installation styles from kubectl completion install if you prefer
https://kubernetes.io/docs/tasks/tools/install-kubectl/#enable-kubectl-autocompletion

You will need to have cnf-conformance executable in your current PATH for this to work properly.

```
./cnf-conformance completion -l error > test.sh
source test.sh
```
</p>
</details>

<details><summary>Other Information on Crystal Builds</summary>
<p>
The CNF Conformance Test Suite is modeled after make, or if you're familiar with Ruby, [rake](https://github.com/ruby/rake). Conformance tests are created via tasks using the Crystal library, [SAM.cr](https://github.com/imdrasil/sam.cr).

To run the automated test suite within the source clone:

```
crystal spec
```
</p></details>

### Setup
Now that we have a `cnf-conformance` binary, we can run `setup` to ensure it has all the pre-requisites needed in order to successfully run tests and setup required cnfs/ directory and other files required for cnf-conformance.

- Run the following to setup cnf-conformance:
  ```
  ./cnf-conformance setup
  ```
- If you have crystal installed, you can also run by:
  ```
  crystal src/cnf-conformance.cr setup
  ```
This should display output of all the pre-requisites (and install helm if not found on the system you intend to run from). Any missing requirements will need to be satisfied before proceeding or could result in errors, etc.

### Configuration
Now that cnf-conformance is installed and setup, we can now run CNF workloads and tests. We recommend installing and running a sample CNF to ensure cnf-conformance is operational and set expectations of the output.


#### Configuring an example CNF

To use CoreDNS as an example CNF. Download the conformance configuration to test CoreDNS:

- Make sure you are in your cnf-conformance/ source repo checkout directory and do the following:
  ```
  curl -o cnf-conformance.yml https://raw.githubusercontent.com/cncf/cnf-conformance/main/example-cnfs/coredns/cnf-conformance.yml
  ```
- Prepare the test suite to use the CNF by running:
  ```
  # via built binary
  ./cnf-conformance cnf_setup cnf-config=./cnf-conformance.yml
  ```
  Or
  ```
  # via crystal
  crystal src/cnf-conformance.cr cnf_setup cnf-config=./cnf-  conformance.yml
  ```

There are other examples in the [examples cnfs](https://github.com/cncf/cnf-conformance/tree/main/example-cnfs) folder if you would like to test others.

#### NOTE: CNF **must** have a [helm chart](https://helm.sh/)

- To pass all current tests
- To support auto deployment of the CNF from the ([cnf-conformance.yml](https://github.com/cncf/cnf-conformance/blob/main/CNF_CONFORMANCE_YML_USAGE.md)) configuration file.

### Running cnf-conformance for the first time

#### Running Tests

If you want to run all tests for CoreDNS Example CNF, do the following (this is assuming your `cnf_setup` ran without errors in the [configuration](#Configuring-an-example-CNF) steps:)
_For complete usage, see the [USAGE.md](USAGE.md) doc._

```
./cnf-conformance all
```

The following will run only workload tests:
```
./cnf-conformance workload 
```

The following would run only the platform tests:
```
./cnf-conformance platform 
```
You can also run via `crystal` by replacing the `./cnf-conformance` with `crystal spec src/cnf-conformance.cr` and then the argument.

#### More Example Usage (also see the [complete usage documentation](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md))

```
# These assume you've already run the cnf_setup pointing at a cnf-conformance.yml config above. You can always specify your config at the end of each command as well, eg:
./cnf-conformance all cnf-config=<path to your config yml>/cnf-conformance.yml

# Runs all ga tests (generally available workload and platform tests)
./cnf-conformance all

# Runs all alpha, beta and ga tests
./cnf-conformance all alpha

# Runs all beta and ga tests
./cnf-conformance all beta

# Run all wip, alpha, beta, and ga tests
./cnf-conformance all wip

# Run all tests in the configureation lifecycle category
./cnf-conformance configuration_lifecycle

# Run all tests in the installability
./cnf-conformance installability
```

#### Checking Results

In the console where the test suite runs:
- PASSED or FAILED will be displayed for the tests

A test log file, eg. `cnf-conformance-results-20201216.txt`, will be created which lists PASS or FAIL for every test based on the date.

For more details on points, see our [POINTS.md](./POINTS.md) documentation.

#### Cleaning Up

Run the following to cleanup the specific cnf-conformance test:
```
./cnf-conformance cnf_cleanup cnf-config=./cnf-conformance.yml
```
You can also run `cleanall` and cnf-conformance will attempt to cleanup everything.

_NOTE: Cleanup does not handle manually deployed CNFs_

### Ready to Bring Your Own CNF?
You can check out our [CNF_CONFORMANCE_YML_USAGE.md](https://github.com/cncf/cnf-conformance/blob/main/CNF_CONFORMANCE_YML_USAGE.md) document on what is required to bring or use your own CNF.

- Follow the [INSTALL](https://github.com/cncf/cnf-conformance/blob/main/INSTALL.md) or [SOURCE-INSTALL](https://github.com/cncf/cnf-conformance/blob/main/SOURCE-INSTALL.md) to build the binary.
- Now head over to [CNF_CONFORMANCE_YML_USAGE.md](https://github.com/cncf/cnf-conformance/blob/main/CNF_CONFORMANCE_YML_USAGE.md) for more detailed steps.
