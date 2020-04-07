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