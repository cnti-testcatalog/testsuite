#!/bin/bash

TOKEN=$1

if [ -z "$1" ]; then
   echo "USAGE: ./cleanup_runners.sh <GITHUB_RUNNER_TOKEN>"
   exit 1
fi

#TOKEN=$(curl  -XPOST -H "authorization: token ${GITHUB_TOKEN}" https://api.github.com/repos/cncf/cnf-testsuite/actions/runners/registration-token | jq -r .token)

RUNNER_CONTAINERS=( $(docker ps --filter "name=unh-runner" --format '{{.Names}}' | xargs) )
docker exec ${RUNNER_CONTAINERS[1]} "sh -c 'kind delete clusters \$(kind get clusters)'"
for runner in  "${RUNNER_CONTAINERS[@]}"; do
   docker exec $runner /actions-runner/bin/Runner.Listener remove --token $TOKEN
done
sudo systemctl stop docker
sudo rm -rf /var/lib/docker/*
sudo systemctl start docker
sudo rm -rf /tmp/*
sudo rm -rf /shared/
sudo rm -rf /runner-tmp/
