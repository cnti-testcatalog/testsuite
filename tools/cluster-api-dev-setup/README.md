how to cluster api
---

based on cluster-api/docs/book/src/developer/guide.md


## prereqs

- existing cluster https://cluster-api.sigs.k8s.io/user/quick-start.html#install-andor-configure-a-kubernetes-cluster
- `clusterclt` https://cluster-api.sigs.k8s.io/user/quick-start.html#install-clusterctl
- a registry. you can easily setup one with https://github.com/tilt-dev/kind-local/
  - `KIND_CLUSTER_NAME='kind-registry' ./kind-with-registry.sh` 



``` bash
# https://github.com/kubernetes-sigs/cluster-api/issues/3013#issuecomment-668154466
export KIND_EXPERIMENTAL_DOCKER_NETWORK=bridge

cat > kind-cluster-with-extramounts-with-registry-access.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- | # https://github.com/tilt-dev/kind-local/blob/master/kind-with-registry.sh
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5000"]
    endpoint = ["http://kind-registry:5000"]
# NOTE DOES NOT WORK WITHOUT kubeadm PATCHES!
kubeadmConfigPatches:
- |
  apiVersion: kubeadm.k8s.io/v1
  kind: ClusterConfiguration
  metadata:
    name: config
  networking:
    serviceSubnet: 10.0.0.0/16
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /var/run/docker.sock
        containerPath: /var/run/docker.sock
EOF

kind create cluster --name kind-cluster-api-manager --config kind-cluster-with-extramounts-with-registry-access.yaml

kind get kubeconfig --name kind-cluster-api-manager > kind-cluster-api-manager-kubeconfig.yaml
export KUBECONFIG=$(pwd)/kind-cluster-api-manager-kubeconfig.yaml

# make sure to use the same KUBECONFIG in any other windows
echo $KUBECONFIG
# copy and the path and export it as KUBECONFIG in other terminal windows
export path-to-your/kind-cluster-api-manager-kubeconfig.yaml

cat > kind-local-cluster-config-map.yaml <<EOF
# run the script from https://github.com/tilt-dev/kind-local first!
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:5000"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

kubectl apply -f kind-local-cluster-config-map.yaml
```





## build docker containers

``` bash
git clone https://github.com/kubernetes-sigs/cluster-api --branch v0.3.9

## parts of the cluster api dev setup scripts try, and generally fail lol, to install cert-manager just install ahead of time to avoid the headaches
helm repo add jetstack https://charts.jetstack.io
helm install --create-namespace \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v0.16.1 \
  --set installCRDs=true


cd < parent_dir i.e. ../ >

# i know this says aws even though you won't be using it
# the tilfile python script breaks if this isn't there trust me lol
git clone git@github.com:kubernetes-sigs/cluster-api-provider-aws.git

cd ../cluster-api



cat > tilt-settings.json <<EOF
{
    "default_registry": "localhost:5000",
    "provider_repos": [],
    "enable_providers": [
        "docker",
        "kubeadm-bootstrap",
        "kubeadm-control-plane"
    ]
}
EOF
```



patch `Tiltfile`


``` diff
william@Will-LAPTOP-L47SIB7:/mnt/c/Users/william/UNSYNCED-symlinked-to-linux/cluster-api$ git diff
diff --git a/Tiltfile b/Tiltfile
index ef4a26158..5fde5a684 100644
--- a/Tiltfile
+++ b/Tiltfile
@@ -161,7 +161,10 @@ metadata:
   namespace: cert-manager-test
 spec:
   dnsNames:
-    - example.com
+    - *.svc.cluster.local
+    - *.docker.internal
+    - localhost
+    - 127.0.0.1
   secretName: selfsigned-cert-tls
   issuerRef:
     name: test-selfsigned
@@ -176,7 +179,7 @@ def enable_provider(name):
     p = providers.get(name)

     context = p.get("context")
-    go_main = p.get("go_main")
+    go_main = p.get("go_main", "main.go")

     # Prefix each live reload dependency with context. For example, for if the context is
     # test/infra/docker and main.go is listed as a dep, the result is test/infra/docker/main.go. This adjustment is
@@ -263,9 +266,9 @@ def deploy_cert_manager():
     local("kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager-webhook")

     # 2. create a test certificate
-    local("cat << EOF | kubectl apply -f - " + cert_manager_test_resources + "EOF")
-    local("kubectl wait --for=condition=Ready --timeout=300s -n cert-manager-test certificate/selfsigned-cert ")
-    local("cat << EOF | kubectl delete -f - " + cert_manager_test_resources + "EOF")
+    # local("cat << EOF | kubectl apply -f - " + cert_manager_test_resources + "EOF")
+    # local("kubectl wait --for=condition=Ready --timeout=300s -n cert-manager-test certificate/selfsigned-cert ")
+    # local("cat << EOF | kubectl delete -f - " + cert_manager_test_resources + "EOF")

```



install tilt 

```
brew install tilt
```

run tilt

```
tilt up
```



wait for it to build all of the docker containers they are used to build control plane nodes and such



push the docker images to ur local registry

```
docker tag localhost:5000/gcr.io_k8s-staging-cluster-api_cluster-api-controller:tilt-59e7996872fb6708 localhost:5000/gcr.io_k8s-staging-cluster-api_cluster-api-controller

docker push localhost:5000/gcr.io_k8s-staging-cluster-api_cluster-api-controller
```



## Install dev docker infrastructure provider so `clusterctl` can use it

based on https://networkop.co.uk/post/2020-05-cluster-api-intro/



``` bash
cat > clusterctl-settings.json <<EOF
{
  "providers": ["cluster-api","bootstrap-kubeadm","control-plane-kubeadm", "infrastructure-docker"]
}
EOF

./cmd/clusterctl/hack/local-overrides.py
```



The `local-overrides.py` script  will give you a `clusterctl` command to run ...  **but don't run it yet!**



``` bash
cat > ~/.cluster-api/clusterctl.yaml <<EOF
providers:
  - name: docker
    url: $HOME/.cluster-api/overrides/infrastructure-docker/v0.3.0/infrastructure-components.yaml
    type: InfrastructureProvider
EOF
```

fix up the yaml for the infra provider

``` bash

cd ~/.cluster-api/overrides

# check in all of the subdirectories and make sure each .yaml file creates CORRECT! Namespace resources 

# re: https://github.com/kubernetes-sigs/cluster-api/issues/3426#issuecomment-679966615
# also re: https://networkop.co.uk/post/2020-05-cluster-api-intro/

# inside of 

vim cluster-api/v0.3.0/core-components.yaml

# change name: system to name: capi-system

# then inside of

control-plane-kubeadm/v0.3.0/control-plane-components.yaml

# change namespace to capi-kubeadm-control-plane-system


# then inside of 

vim bootstrap-kubeadm/v0.3.0/bootstrap-components.yaml

# change namepsace to capi-kubeadm-bootstrap-system

# then inside of 

vim infrastructure-docker/v0.3.0/infrastructure-components.yaml

# change name: capi-system to name: capd-system

# also replace the image image: gcr.io/k8s-staging-cluster-api/capd-manager:dev
# with the local version that was builit by tilt in teh first step for you i.e

docker images localhost:5000/gcr.io_k8s-staging-cluster-api_capd-manager

docker tag latest localhost:5000/gcr.io_k8s-staging-cluster-api_capd-manager

docker push localhost:5000/gcr.io_k8s-staging-cluster-api_capd-manager
```

-

now you can run the `clusterctl` command i.e.

```
# if you have a cert-manager failure just try again	
clusterctl init  --core cluster-api:v0.3.0  --bootstrap kubeadm:v0.3.0    --control-plane kubeadm:v0.3.0    --infrastructure docker:v0.3.0 
```



verify everything is ready 


```
kubectl get deploy -A | grep cap
kubectl -n capi-system describe pod capd-controller-manager<TAB>-<TAB>
```



## Build a workload cluster

(9-15-2020: stuck here: its looking for a `CNI_RESOURCES` variable i don;t know how to set)



(9-16-2020 workin here feel close)

```
CNI_RESOURCES="$(cat test/e2e/data/cni/kindnet/kindnet.yaml)" \
DOCKER_POD_CIDRS="172.17.0.0/16" \
DOCKER_SERVICE_CIDRS="192.168.0.0/16" \
DOCKER_SERVICE_DOMAIN="cluster.local" \
clusterctl config cluster capd --kubernetes-version v1.17.5 \
--from ./test/e2e/data/infrastructure-docker/cluster-template.yaml \
--target-namespace default \
--control-plane-machine-count=1 \
--worker-machine-count=2 \
> capd.yaml
```



```
kubectl apply -f capd.yaml
```





https://alexbrand.dev/post/understanding-the-role-of-cert-manager-in-cluster-api/