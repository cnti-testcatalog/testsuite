#!/bin/bash

until [[ $(kubectl get deployment --namespace=litmus chaos-operator-ce -o=jsonpath='{.status.readyReplicas}') == $(kubectl get deployment --namespace=litmus chaos-operator-ce -o=jsonpath='{.status.replicas}') ]] 
do 
  echo 'waitting until desired Litmus replicas are running'
  sleep 1
done
