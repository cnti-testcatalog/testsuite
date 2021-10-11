#!/bin/bash

num=0

until [[ $(kubectl get deployment --namespace=litmus chaos-operator-ce) ]]
do 
    echo 'Waiting until Litmus Deployment exists'
    sleep 1
    num=` expr $num + 1`
    if [[ $num == 20 ]]; then
        echo "Timeout waiting for Litmus"
        exit 1
    fi
done


until [[ $(kubectl get deployment --namespace=litmus chaos-operator-ce -o=jsonpath='{.status.readyReplicas}') == $(kubectl get deployment --namespace=litmus chaos-operator-ce -o=jsonpath='{.status.replicas}') ]]
do 
  echo 'waiting until desired Litmus replicas are running'
  sleep 1
  num=` expr $num + 1`
  if [[ $num == 20 ]]; then
    echo "Timeout waiting for Litmus"
    exit 1
  fi
done
