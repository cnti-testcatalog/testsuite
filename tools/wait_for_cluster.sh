#!/bin/bash

echo "Running Wait for Cluster"
until [[ $(kubectl get pods --namespace=kube-system) ]]
do
    echo "Waiting for api-server to be ready"
    sleep 1
done

until [[ $(kubectl get pods --namespace=kube-system --field-selector=status.phase=Running | wc -l) == $(kubectl get pods --namespace=kube-system | wc -l) ]]
do
  echo "Waiting for system pods to be ready"
  echo "System Pod Count: $(kubectl get pods --namespace=kube-system | wc -l)" 
  echo "Ready Pod Count: $(kubectl get pods --namespace=kube-system --field-selector=status.phase=Running | wc -l)"
  sleep 1
done
