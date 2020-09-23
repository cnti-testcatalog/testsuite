how to cluster api
---




## prereqs

- bootstrap cluster
- kind
- kustomize
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

kind create cluster --name kind-cluster-api-manager --config kind-cluster-with-extramounts-with-registry-access.yaml --kubeconfig dslafjsdkjfakls

kind get kubeconfig --name kind-cluster-api-manager > kind-cluster-api-manager-kubeconfig.yaml
export KUBECONFIG=$(pwd)/kind-cluster-api-manager-kubeconfig.yaml

# make sure to use the same KUBECONFIG in any other windows
echo $KUBECONFIG

# test that you are using teh right cluster. node json should include name "kind-cluster-api-manager"
kubectl cluster-info dump 

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

cd ./cluster-api


# https://github.com/kubernetes-sigs/cluster-api/blob/v0.3.9/docs/book/src/tasks/experimental-features/experimental-features.md

cat > tilt-settings.json <<EOF
{
    "default_registry": "localhost:5000",
    "provider_repos": [],
    "enable_providers": [
        "docker",
        "kubeadm-bootstrap",
        "kubeadm-control-plane"
    ],
    "kind_cluster_name": "kind-cluster-api-manager",
      "kustomize_substitutions": {
    "EXP_CLUSTER_RESOURCE_SET": "true",
    "EXP_MACHINE_POOL": "false"
  }
}
EOF
```



patch `Tiltfile`


``` diff
diff --git a/Tiltfile b/Tiltfile
index d00a07d71..abec91ecd 100644
--- a/Tiltfile
+++ b/Tiltfile
@@ -225,7 +225,7 @@ def enable_provider(name):

     # Apply the kustomized yaml for this provider
     yaml = str(kustomize_with_envsubst(context + "/config"))
-    k8s_yaml(blob(yaml))
+    k8s_yaml(blob(yaml), allow_duplicates=True)
```



install tilt 

```
brew install tilt
```

run tilt

```
tilt up
```



wait for it to build all of the docker containers they are used to build control plane nodes and such (you will need them in the yaml provider section below)




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

(if needed) fix up the yaml for the infra provider

``` bash

cd ~/.cluster-api/overrides

# check in all of the subdirectories and make sure each .yaml file creates CORRECT! Namespace resources 

# re: https://github.com/kubernetes-sigs/cluster-api/issues/3426#issuecomment-679966615
# also re: https://networkop.co.uk/post/2020-05-cluster-api-intro/

# inside of 

vim cluster-api/v0.3.0/core-components.yaml

# in the namspace resource make sure
# name: capi-webhook-system

# then inside of

control-plane-kubeadm/v0.3.0/control-plane-components.yaml

# in the namspace resource make sure
# name: capi-kubeadm-control-plane-system


# then inside of 

vim bootstrap-kubeadm/v0.3.0/bootstrap-components.yaml

# in the namspace resource make sure
# name: capi-kubeadm-bootstrap-system


# then inside of 

vim infrastructure-docker/v0.3.0/infrastructure-components.yaml

# in the namspace resource make sure
# name: capd-system

# also replace the image image: gcr.io/k8s-staging-cluster-api/capd-manager:dev
# with the local version that was builit by tilt in teh first step for you i.e


# finall push the images built by tilt to registry if needed

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



```
CNI_RESOURCES="$(cat test/e2e/data/cni/kindnet/kindnet.yaml)" \
DOCKER_POD_CIDRS="172.17.0.1/16" \
DOCKER_SERVICE_CIDRS="127.0.0.240/28" \
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



Now follows insturctions here to access workload clusters

https://cluster-api.sigs.k8s.io/user/quick-start.html#accessing-the-workload-cluster



Assess cluster state

```
kubectl get cluster --all-namespaces
kubectl get kubeadmcontrolplane --all-namespaces
```



Accss teh cluster that was created by cluster api

```

clusterctl get kubeconfig capd > capd.kubeconfig


sed -i -e "s/server:.*/server: https:\/\/$(docker port capd-lb 6443/tcp | sed "s/0.0.0.0/127.0.0.1/")/g" capd.kubeconfig

sed -i -e "s/certificate-authority-data:.*/insecure-skip-tls-verify: true/g" capd.kubeconfig


export KUBECONFIG=$(pwd)/test.kubeconfig

kubectl get nodes
```



sources:

cluster-api/docs/book/src/developer/guide.md

based on https://networkop.co.uk/post/2020-05-cluster-api-intro/

https://alexbrand.dev/post/understanding-the-role-of-cert-manager-in-cluster-api/





