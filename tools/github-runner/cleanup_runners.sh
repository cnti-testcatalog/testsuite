#!/bin/bash

RUNNERS=(
    136.144.55.87
    136.144.55.243
    139.178.69.151
    139.178.69.153
    139.178.68.167
    86.109.1.243
    139.178.68.111
    139.178.68.103
    139.178.68.93
    139.178.68.107
    136.144.54.249)


#TOKEN=$(curl  -XPOST -H "authorization: token ${GITHUB_TOKEN}" https://api.github.com/repos/cncf/cnf-testsuite/actions/runners/registration-token | jq -r .token)

for node in "${RUNNERS[@]}"; do
    RUNNER_CONTAINERS=( $(ssh root@$node docker ps --filter "name=github-runner" --format '{{.Names}}' | xargs) )
    ssh root@$node docker exec ${RUNNER_CONTAINERS[1]} "sh -c 'kind delete clusters \$(kind get clusters)'"
    for runner in  "${RUNNER_CONTAINERS[@]}"; do
      ssh root@$node docker exec $runner "/actions-runner/bin/Runner.Listener remove --token $TOKEN"
    done
    ssh root@$node "systemctl stop docker"
    ssh root@$node "rm -rf /var/lib/docker/*"
    ssh root@$node "systemctl start docker"
    ssh root@$node "rm -rf /tmp/*"
    ssh root@$node "rm -rf /shared/"
    ssh root@$node "rm -rf /runner-tmp/"
done
