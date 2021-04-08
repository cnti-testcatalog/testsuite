Installing the CNF Conformance Test Suite
---
### Overview
This INSTALL guide will detail the minimum requirements needed for cnf-conformance while then providing installation with configuration steps to run the cnf-conformance binary from both a binary installation and source installation method.

### Table of Contents
* [**Pre-Requisites**](#Pre-Requisites)
* [**Installation**](#Installation)
* [**Preparation**](#Preparation)
* [**Configuration**](#Configuration)
* [**Running cnf-conformance for the first time**](#Running-cnf-conformance-for-the-first-time)

### Pre-Requisites
This will detail the required minimum requirements needed in order to support cnf-conformance.

#### Minimum Requirements
* **kubernetes cluster** *(Working k8s cluster, see [supported k8s and installation details](#Details-on-supported-k8s-clusters-and-installation) on installation.*
* **kubectl** *(run commands against k8 clusters, see [installing kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for more details.*
* **curl**
* **helm 3.1.1** *or newer* *(cnf-conformance installs if not found locally)*

#### Requirements for source installation
*Everything detailed in the [minimum requirements](https://hackmd.io/6h7NXdHnR4qUYgnnQPy5UA#Required) and the following:*
* **git** *(used to check out code from github)*
* **crystal-lang** version 0.35.1 *(to compile the source and build the binary, see [crystal installation](https://crystal-lang.org/install/))*
* **shards** ([dependency manager](https://github.com/crystal-lang/shards) for crystal-lang)



---


#### Details on supported k8s clusters and installation:
<details><summary>Click here to drop down details</summary>

<p>

##### Supported k8s Clusters
- [Access](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/) to a working [Certified K8s](https://cncf.io/ck) cluster via [KUBECONFIG environment variable](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/#set-the-kubeconfig-environment-variable). (See [K8s Getting started guide](https://kubernetes.io/docs/setup/) for options)
-  Follow the optional instructions below if you don't already have a k8s cluster setup

##### Kind

- Follow the [kind install](KIND-INSTALL.md) instructions to setup a cluster in [kind](https://kind.sigs.k8s.io/)

##### CNF-Testbed

- You can clone the CNF-Testbed project if you have an account at Equinix Metal (formerly Packet.net). Get the code by running the following:

```
git clone https://github.com/cncf/cnf-testbed.git
```

- Clone the K8s-infra repo then follow the [prerequisites](https://github.com/cncf/cnf-testbed/tree/master/tools#pre-requisites) for [deploying a K8s cluster](https://github.com/cncf/cnf-testbed/tree/master/tools#deploying-a-kubernetes-cluster-using-the-makefile--ci-tools) for a Equinix Metal host.
- If you already have IP addresses for your provider, and you want to manually install a K8s cluster, you can use k8s-infra to do this within your cnf-testbed repo clone.

```
cd tools/ && git clone https://github.com/crosscloudci/k8s-infra.git
```

- Now follow the [K8s-infra quick start](https://github.com/crosscloudci/k8s-infra/blob/master/README.md#quick-start) for instructions on how to install.

</p>
</details>



---


### Installation

We support the following methods of installing the cnf-conformance suite:

- [Curl installation](#Curl-Binary-Installation) (via latest binary release)
- [Latest Binary](https://github.com/cncf/cnf-conformance/releases/latest) (manual download)
- From [**Source**](#Source-Install) on github.


#### Curl Binary Installation

There are two methods to install via curl, we prefer the first method (the others including the manual and source install are optional):

- This first command using curl will download, install, and export the path automatically (recommended method):

```
source <(curl https://raw.githubusercontent.com/cncf/cnf-conformance/main/curl_install.sh)
```

<details><summary>Click here for the alternate curl and manual install method</summary>
<p>

- The other curl method to download and install requires you to export the PATH to the location of the executable:
```
curl https://raw.githubusercontent.com/cncf/cnf-conformance/main/curl_install.sh | bash
```

- The Latest Binary (or you can select a previous release if desired) can be pulled down with wget, curl or you're own preferred method. Once downloaded you'll need to make the binary executable and manually add to your path:
```
wget https://github.com/cncf/cnf-conformance/releases/download/latest/latest.tar.gz
tar xzf latest.tar.gz
cd cnf-conformance
chmod +x cnf-conformance
export OLDPATH=$PATH; export PATH=$PATH:$(pwd)
```
</p>
</details>

#### Source Install

This is a brief summary for source installations and [does have requirements](#Requirements-for-source-installation) in order to compile a binary from source. To read more on source installation, see the [SOURCE-INSTALL](SOURCE_INSTALL.md) document.

<details><summary> Click here for brief source install details</summary>
<p>

Follow these steps to checkout the source from github and compile a cnf-conformance binary:

```
git clone https://github.com/cncf/cnf-conformance.git
cd cnf-conformance/
shards install
crystal build src/cnf-conformance.cr
```
This should build a cnf-conformance binary in the root directory of the git repo clone.
</p>
</details>

### Preparation

Now that you have cnf-conformance installed, we need to prepare the suite.

First make sure your k8s cluster is accessible (part of the [minimum pre-requisites](#Minimum-Requirements)). You can run the following to verify the cluster: 

```
kubectl cluster-info
```

And it should print a running kubernetes master in the output. Common kubectl errors and issues might relate to your KUBECONFIG variable. You can export to your k8s config by doing the following:

```
export KUBECONFIG=path/to/mycluster.config
```

*Note: We recommend running cnf-conformance on a non-production cluster.*

The next step for cnf-conformance is to run the `setup` which prepares the cnf-conformance suite. This runs pre-reqs to verify you have everything needed in order to run the suite, simply run the following:

```
cnf-conformance setup
```

The test suite by default will pull docker images from https://docker.io. You can set your own username and password with local environment variables by doing the following:

```
export DOCKERHUB_USERNAME=<USERNAME>
export DOCKERHUB_PASSWORD=<PASSWORD>
```

Please refer to the [CNF_CONFORMANCE_YML_USAGE.md](CNF_CONFORMANCE_YML_USAGE.md#Using-a-Private-Registry) for details on using a private registry.


<details><summary>Install Tab Completion for cnf-conformance (Optional)</summary>

Check out our (experimental) support for tab completion!

NOTE: also compatible with the installation styles from kubectl completion install if you prefer
https://kubernetes.io/docs/tasks/tools/install-kubectl/#enable-kubectl-autocompletion

```
cnf-conformance completion -l error > test.sh
source test.sh
```
</details>

### Configuration
Now cnf-conformance is setup, we're ready to configure it to point at a CNF to test.

#### Using an Example CNF

- If you want to use an example CNF, you can download our CoreDNS example CNF by doing the following:

```
wget -O cnf-conformance.yml https://raw.githubusercontent.com/cncf/cnf-conformance/main/example-cnfs/coredns/cnf-conformance.yml
```
- The wget gets a working config file, now tell cnf-conformance to use it by doing the following:
```
cnf-conformance cnf_setup cnf-config=./cnf-conformance.yml
```

- There are other examples in the [examples-cnfs](https://github.com/cncf/cnf-conformance/tree/master/example-cnfs) directory that can be used for testing as well.

#### Bring Your Own CNF

If you've brought your own CNF to test, review the [CNF_CONFORMANCE_YML_USAGE.md](CNF_CONFORMANCE_YML_USAGE.md) document on formatting and other requirements.

If you've followed the [CNF_CONFORMANCE_YML_USAGE.md](CNF_CONFORMANCE_YML_USAGE.md) guide and have your cnf-conformance.yml ready, you can run the same command we ran for the example CNF to set it up:

```
cnf-conformance cnf_setup cnf-config=./cnf-conformance.yml
```

### Running cnf-conformance for the first time

#### Running Tests

If you want to run all tests, do the following (this is assuming your `cnf_setup` ran without errors in the [configuration](#Configuration) steps:)
_For complete usage, see the [USAGE.md](USAGE.md) doc._

```
cnf-conformance all
```

The following will run only workload tests:
```
cnf-conformance workload 
```

The following would run only the platform tests:
```
cnf-conformance platform 
```

#### Checking Results

In the console where the test suite runs:
- PASSED or FAILED will be displayed for the tests

A test log file, eg. `cnf-conformance-results-20201216.txt`, will be created which lists PASS or FAIL for every test based on the date.

For more details on points, see our [POINTS.md](./POINTS.md) documentation.

#### Cleaning Up

Run the following to cleanup the specific cnf-conformance test (this is assuming you installed the cnf-conformance.yml in your present working directory):
```
cnf-conformance cnf_cleanup cnf-config=./cnf-conformance.yml
```
You can also run `cleanall` and cnf-conformance will attempt to cleanup everything.

_NOTE: Cleanup does not handle manually deployed CNFs_
