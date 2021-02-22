Quick Install Instructions for the CNF Conformance Test Suite
---
### Overview
This is a quick install to get the CNF Test Suite up and running quickly with the latest stable binary.

### Table of Contents
* [**Pre-Requisites**](#Pre-Requisites)
* [**Installation**](#Installation)
* [**Preparation**](#Preparation)
* [**CNF Configuration**](#CNF-Configuration)

### Pre-Requisites
This assumes you have a working kubernetes cluster, wget, curl, helm 3.1.1 or greater on your system already.

---

### Installation
Install the latest test suite binary:

```
source <(curl https://raw.githubusercontent.com/cncf/cnf-conformance/master/curl_install.sh)
```

### Preparation
Run `setup` which prepares the cnf-conformance suite:

```
cnf-conformance setup
```

### CNF Configuration
Now pull down an example CNF to test with and configure the test suite with it:

```
wget -O cnf-conformance.yml https://raw.githubusercontent.com/cncf/cnf-conformance/master/example-cnfs/coredns/cnf-conformance.yml
cnf-conformance cnf_setup cnf-config=./cnf-conformance.yml
```
This should get produce results using our example CNF (coredns). If you see any errors or failures, you might need to read our more indepth [INSTALL.md](INSTALL.md) documentation on getting CNF Test suite working. We also have a guide if you prefer to [install by source](INSTALL_SOURCE.md).
