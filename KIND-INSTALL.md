### Install [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux)

### Install [Kind](https://github.com/kubernetes-sigs/kind#installation-and-usage)
```
GO111MODULE="on" go get sigs.k8s.io/kind@v0.7.0
```

### To create a cluster
```
kind create cluster
```

### To check for running pods (including k8s system pods)
```
kubectl get pods --all-namespaces
```

### Notice the KUBECONFIG is not set
```
echo $KUBECONFIG
```

### It overwrites the ~/.kube/config by default
```
ls -l ~/.kube/config
cat ~/.kube/config 
```

### Use the --kubeconfig option to have multiple kubeconfig and specify a cluster name with --name
```
kind create cluster --kubeconfig myclusterconfig --name mycluster
KUBECONFIG=myclusterconfig kubectl get pods --all-namespaces
```

### Export the KUBECONFIG

```
cp -a ~/.kube/config mykubeconfig
export KUBECONFIG=`pwd`/myclusterconfig
```

## Add Multus and CNI plugins to Kind cluster
Start by installing Multus in the cluster:
```
curl https://raw.githubusercontent.com/intel/multus-cni/master/images/multus-daemonset.yml | kubectl apply -f -
```

Check the name of your node(s) (default: kind-control-plane)
```
docker ps
```

Open a shell on the node(s), and install the CNI binaries (repeat for every node where CNIs should be installed)
```
docker exec -it <name of node> /bin/bash
$ apt update && apt install -y wget
$ wget https://github.com/containernetworking/plugins/releases/download/v0.8.5/cni-plugins-linux-amd64-v0.8.5.tgz
$ tar -C /opt/cni/bin/ -zxvf cni-plugins-linux-amd64-v0.8.5.tgz
$ (optional) rm cni-plugins-linux-amd64-v0.8.5.tgz
```

Now you can use CNFs that require Multus and CNIs, e.g. [examples/ip-forwarder](https://github.com/cncf/cnf-conformance/tree/master/example-cnfs/ip-forwarder)
