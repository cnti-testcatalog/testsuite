#!/bin/bash
# Spec test commands
git clone https://github.com/kubernetes-sigs/cluster-api --depth 1 --branch v0.3.9 
cd cluster-api

cat > clusterctl-settings.json <<EOF
{
  "providers": ["cluster-api","bootstrap-kubeadm","control-plane-kubeadm", "infrastructure-docker"]
}
EOF

./cmd/clusterctl/hack/local-overrides.py

cat > ~/.cluster-api/clusterctl.yaml <<EOF
providers:
  - name: docker
    url: $HOME/.cluster-api/overrides/infrastructure-docker/v0.3.0/infrastructure-components.yaml
    type: InfrastructureProvider
EOF

clusterctl init  --core cluster-api:v0.3.0  --bootstrap kubeadm:v0.3.0    --control-plane kubeadm:v0.3.0    --infrastructure docker:v0.3.0

sleep 10

CNI_RESOURCES="$(cat test/e2e/data/cni/kindnet/kindnet.yaml)" \
DOCKER_POD_CIDRS="192.168.0.0/16" \
DOCKER_SERVICE_CIDRS="172.17.0.0/16" \
DOCKER_SERVICE_DOMAIN="cluster.local" \
clusterctl config cluster capd --kubernetes-version v1.17.5 \
--from ./test/e2e/data/infrastructure-docker/cluster-template.yaml \
--target-namespace default \
--control-plane-machine-count=1 \
--worker-machine-count=2 \
> capd.yaml

kubectl apply -f capd.yaml || true
