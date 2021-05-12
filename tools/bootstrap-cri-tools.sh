#!/bin/bash

docker build -t ${1} ./cri-tools/ 

docker push ${1}

#TODO Add support for docker credentials.

cat <<EOF > cri-tools-manifest.yml
apiVersion: apps/v1
kind: DaemonSet
metadata:
    name: cri-tools
spec:
  selector:
    matchLabels:
      name: cri-tools
  template:
    metadata:
      labels:
        name: cri-tools
    spec:
      containers:
        - name: cri-tools
          image: ${1}
          command: ["/bin/sh"]
          args: ["-c", "sleep infinity"]
          volumeMounts:
          - mountPath: /run/containerd/containerd.sock
            name: containerd-volume
      volumes:
      - name: containerd-volume
        hostPath:
          path: /var/run/containerd/containerd.sock
EOF

kubectl create -f cri-tools-manifest.yml

NODE_ARRAY=$(kubectl get nodes -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ " "}}{{end}}{{end}}')

echo "Nodes: ${NODE_ARRAY[@]}"

for node in ${NODE_ARRAY[@]}
do
    until [[ $(kubectl get pods --field-selector spec.nodeName=$node -l name=cri-tools -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') == "True" ]]; do
        echo "Waiting for pod"
        sleep 1
    done
done
