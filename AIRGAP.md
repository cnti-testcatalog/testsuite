# Air-gap documentation

#### Overview of the air-gap installation steps

The following install instructions will create a tarball of all the necessary cnf-testsuite components which will need to be copied to the airgapped environment.  You can then run the `setup` command to bootstrap the K8s cluster and install the cnf-testsuite components onto your K8s cluster.  Optionally you can use the cnf_setup command to create or add to an existing tarball created with the required components for your own CNF.

#### Quick install steps for bootstrapping an air-gapped environment

1. The first step requires internet access, which creates the initial tarball of the required components for cnf-testsuite:
```
./cnf-testsuite airgapped output-file=/tmp/airgapped.tar.gz
```
2. The next step after the airgapped.tar.gz is copied to your air-gapped environment host that has kubectl access will setup cnf-testsuite (offline without internet):
```
./cnf-testsuite setup offline=/tmp/airgapped.tar.gz

# To run the set suite in air-gapped mode
./cnf-testsuite workload offline=true
```

#### Quick install steps for CNF install (optional)

1. This requires internet access, which pulls down necessary components the CNF requires. This also assumes your airgapped k8s has already been bootstrapped (previous quick install steps):

`./cnf-testsuite cnf_setup cnf-config=example-cnfs/coredns/cnf-testsuite.yml output-file=/tmp/cnf.tar.gz`

2. In the air-gapped environment (offline without internet access) after copying the tarball, the following command will setup the CNF:

`./cnf-testsuite cnf_setup cnf-config=example-cnfs/coredns/cnf-testsuite.yml input-file=/tmp/cnf.tar.gz`

#### Detailed explanation of the air-gap process

**Step 1:** The air-gap process starts out downloading the prerequisites for bootstrapping the airgapped cluster, the upstream testing tools, and CNFs into a tarball.  It does this by:
* Tarballing any cnf-testsuite internal tools
* Tarballing the upstream projects' docker images

When installing the upstream projects and/or the cnfs, there are three styles of installation into K8s that have to be managed:

* **K8s Installation methods**
    * **Helm charts** must be downloaded into a tarball so that they can be executed without accessing a remote helm repository.  
        * The air-gap process needs to inspect the helm chart tarball and then extract the referenced docker images into docker image tarballs.  
    * **Helm directories**
        * The air-gap process needs to inspect the helm chart directory yaml files and extract the referenced docker images into docker image tarballs.
    * **Manifest directories**
        * As in the helm directory process, a manifest directory must have all of the docker images that are referenced in its yaml files tarballed into valid docker image tarballs.

**Step 2:** The tarball that was created in step 1 needs to be **copied to the air-gapped environment**.  The cnf-testsuite executable will need to be copied into the air-gapped environment as well as the cnf-testsuite.yml config files, and any other files needed for the managing a specific CNF.

**Step 3:** **The bootstrapping process** installs the cnf-testsuite bootstrapping tools on each schedulable node.  It does this by first finding an image that already exists on each node and then creates a DaemonSet named "cri-tools" using the found image.  It then copies the cri and ctr binaries into the DaemonSet pods.

**Step 4:** **The image caching** process uses the cri-tools to cache the saved docker images onto each node.  It achieves this by utilizing the kubectl cp command to copy the tarball onto all schedulable nodes and uses the docker client to load and then cache the images.

**Step 5:** **The install tools** step installs all of the prerequisite tools (using helm, helm directories, or manifest files) that the cnf-testsuite requires for each node.

**Step 6: (optional)** The install CNF (applications) step installs a CNF using the cnf_setup command combined with a user-provided cnf-testuite config file with a helm chart, helm directory, or manifest file.

Note: In order for images to be deployed into an air-gapped enviroment, the images in the helm chart or manifest file need to be set to a specific version (otherwise the image pull policy will force a retrieval of the image which it will not be able to pull).
