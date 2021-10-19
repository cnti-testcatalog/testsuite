#!/bin/bash

echo "Running Wait for Cluster"
until [[ $(kubectl get pods --namespace=kube-system) ]]
do
    echo "Waiting for api-server to be ready"
    sleep 1
done

until [[ $(($(kubectl get pods --namespace=kube-system | wc -l)-1)) != $(kubectl -n kube-system get pods -o go-template='{{range $index, $element := .items}}{{range .status.containerStatuses}}{{if .ready}}{{$element.metadata.name}}{{"\n"}}{{end}}{{end}}{{end}}' | wc -l) ]]
do
  echo "Waiting for system pods to be reset"
  echo "System Pod Count: $(($(kubectl get pods --namespace=kube-system | wc -l)-1))" 
  echo "Ready Pod Count: $(kubectl -n kube-system get pods -o go-template='{{range $index, $element := .items}}{{range .status.containerStatuses}}{{if .ready}}{{$element.metadata.name}}{{"\n"}}{{end}}{{end}}{{end}}' | wc -l)"
  sleep 1
done

until [[ $(($(kubectl get pods --namespace=kube-system | wc -l)-1)) = $(kubectl -n kube-system get pods -o go-template='{{range $index, $element := .items}}{{range .status.containerStatuses}}{{if .ready}}{{$element.metadata.name}}{{"\n"}}{{end}}{{end}}{{end}}' | wc -l) ]]
do
  echo "Waiting for system pods to be ready"
  echo "System Pod Count: $(($(kubectl get pods --namespace=kube-system | wc -l)-1))" 
  echo "Ready Pod Count: $(kubectl -n kube-system get pods -o go-template='{{range $index, $element := .items}}{{range .status.containerStatuses}}{{if .ready}}{{$element.metadata.name}}{{"\n"}}{{end}}{{end}}{{end}}' | wc -l)"
  sleep 1
done
