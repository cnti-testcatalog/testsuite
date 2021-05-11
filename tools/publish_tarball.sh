#!/bin/bash


ARRAY=$(kubectl get nodes -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ "\n"}}{{end}}{{end}}')

echo "Nodes: ${ARRAY[@]}"

declare -a CRI_DAEMONS
for node in ${ARRAY[@]}
do
    CRI_DAEMONS+=$(kubectl get pods --field-selector spec.nodeName=$node -l name=cri-tools -o jsonpath='{range .items[*]}{.metadata.name}')
done
echo "CRI_DAEMONS: ${CRI_DAEMONS[@]}"

for daemon in ${CRI_DAEMONS[@]}
do
    kubectl cp ${1} $daemon:/tmp/${1}
    kubectl exec -ti $daemon -- ctr -n=k8s.io image import /tmp/${1}
done
