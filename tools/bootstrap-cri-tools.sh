#!/bin/bash

tar_func () {


  echo "Tar Func for Pod: ${1}"

  CRI_VERSION="v1.17.0"
  CTR_VERSION="1.5.0"
  curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRI_VERSION}/crictl-${CRI_VERSION}-linux-amd64.tar.gz --output crictl-${CRI_VERSION}-linux-amd64.tar.gz
  curl -L https://github.com/containerd/containerd/releases/download/v${CTR_VERSION}/containerd-${CTR_VERSION}-linux-amd64.tar.gz --output containerd-${CTR_VERSION}-linux-amd64.tar.gz
  tar -zxvf crictl-${CRI_VERSION}-linux-amd64.tar.gz -C /tmp
  tar -zxvf containerd-${CTR_VERSION}-linux-amd64.tar.gz -C /tmp
  name=${1}
  kubectl cp /tmp/crictl $name:/usr/local/bin/crictl
  kubectl cp /tmp/bin/ctr $name:/usr/local/bin/ctr
}

if [ "$1" == "registry" ]; then

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

elif [ "$1" == "copy" ]; then
    PODS_ARRAY=( $(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name};{.metadata.namespace} ' --all-namespaces | sed 's/.\{2\}$//') )
    echo "Pods: ${PODS_ARRAY[@]}"

    for pod in ${PODS_ARRAY[@]}
    do
        POD=( $(echo $pod | tr -s ';' ' ') ) 
        echo "Pod: ${POD[0]} Namespace: ${POD[1]}"
        if kubectl exec --namespace=${POD[1]} -ti ${POD[0]} -- cat /bin/sh > /dev/null; then
          break
        fi
    done
    echo "Exec Pod: ${POD[0]}"
    image=$(kubectl get pods ${POD[0]} --namespace=${POD[1]} -o jsonpath='{range .spec.containers[*]}{.image}')
    echo "Image: $image"

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
          image: $image
          command: ["/bin/sh"]
          args: ["-c", "sleep infinity"]
          volumeMounts:
          - mountPath: /run/containerd/containerd.sock
            name: containerd-volume
          - mountPath: /tmp/usr/bin
            name: usrbin
          - mountPath: /tmp/usr/local/bin
            name: local
          - mountPath: /tmp/bin
            name: bin
      volumes:
      - name: containerd-volume
        hostPath:
          path: /var/run/containerd/containerd.sock
      - name: usrbin
        hostPath:
          path: /usr/bin/
      - name: local
        hostPath:
          path: /usr/local/bin/
      - name: bin
        hostPath:
          path: /bin/
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


    for node in ${NODE_ARRAY[@]}
    do
        name=$(kubectl get pods --field-selector spec.nodeName=$node -l name=cri-tools -o jsonpath='{range .items[*]}{.metadata.name}')
        if kubectl exec -ti $name -- cat /tmp/bin/ctr > /dev/null; then
            echo "/tmp/bin/ctr found"
            exit 0
        elif kubectl exec -ti $name -- cat /tmp/usr/bin/ctr > /dev/null; then
            echo "/tmp/usr/bin/ctr found"
            exit 0
        elif kubectl exec -ti $name -- cat /tmp/usr/local/bin/ctr > /dev/null; then
            echo "/tmp/usr/local/bin/ctr found"
            exit 0
        else
            tar_func $name
        fi
    done
fi
