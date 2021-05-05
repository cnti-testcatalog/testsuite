# What is [NAT-CNF](https://github.com/PANTHEONtech/cnf-examples/tree/master/nsm/LFNWebinar)

- See the ../README.md for the workload defintion of this CNF. NSM should be installed before this CNF is installed

# Prerequistes

Follow [Pre-req steps](../../INSTALL.md#pre-requisites), including

- Set the KUBECONFIG environment to point to the remote K8s cluster
- Downloading the binary cnf-testsuite release

### Automated CNF installation

Initialize the conformance suite

```
crystal src/cnf-testsuite.cr setup
```

Configure and deploy nsm-nat as the target CNF

```
crystal src/cnf-testsuite.cr cnf_setup cnf-config=./example-cnfs/pantheon-nsm-nat/cnf-testsuite.yml deploy_with_chart=false
```

Run the all the tests

```
crystal src/cnf-testsuite.cr all
```

Check the results file

Cleanup the cnf test setup (including undeployment of nsm-nat)

```
crystal src/cnf-testsuite.cr cnf_cleanup cnf-config=./example-cnfs/pantheon-nsm-nat/cnf-testsuite.yml
```
