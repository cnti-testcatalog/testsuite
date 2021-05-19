#!/bin/bash


NODE_ARRAY=$(kubectl get nodes -o 'go-template={{range .items}}{{$taints:=""}}{{range .spec.taints}}{{if eq .effect "NoSchedule"}}{{$taints = print $taints .key ","}}{{end}}{{end}}{{if not $taints}}{{.metadata.name}}{{ " "}}{{end}}{{end}}')

echo "Nodes: ${NODE_ARRAY[@]}"

for node in ${NODE_ARRAY[@]}
do
    name=$(kubectl get pods --field-selector spec.nodeName=$node -l name=cri-tools -o jsonpath='{range .items[*]}{.metadata.name}')
    kubectl cp ${1} $name:/tmp/${1}
    kubectl exec -ti $name -- ctr -n=k8s.io image import /tmp/${1}
done
