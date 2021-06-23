#!/bin/bash

RUNNERS=(
    145.40.90.133
    136.144.55.87
    136.144.55.243
    139.178.69.151
    139.178.69.153
    139.178.68.167
    86.109.1.243)

TOKEN=$(curl  -XPOST -H "authorization: token ${GITHUB_TOKEN}" https://api.github.com/repos/cncf/cnf-testsuite/actions/runners/registration-token | jq -r .token)

for node in "${RUNNERS[@]}"; do
    RUNNER_CONTAINERS=( $(ssh root@$node docker ps --filter "name=github-runner" --format '{{.Names}}' | xargs) )
    ssh root@$node docker exec ${RUNNER_CONTAINERS[1]} "sh -c 'kind delete clusters \$(kind get clusters)'"
    for runner in  "${RUNNER_CONTAINERS[@]}"; do
        ssh root@$node docker exec $runner "/actions-runner/bin/Runner.Listener remove --token $TOKEN"
    done
    ssh root@$node sudo systemctl stop docker
    ssh root@$node sudo rm -rf /var/lib/docker/*
    ssh root@$node sudo systemctl start docker
done
