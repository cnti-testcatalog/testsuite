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
