#!/bin/bash

RUNNERS=(
    145.40.90.133
    136.144.55.87
    136.144.55.243
    139.178.69.151
    139.178.69.153
    139.178.68.167
    86.109.1.243)


for node in "${RUNNERS[@]}"; do
    RUNNER_CONTAINERS=( $(ssh root@$node docker ps --filter "name=github-runner" --format '{{.Names}}' | xargs) )
    ssh root@$node docker exec ${RUNNER_CONTAINERS[1]} "sh -c 'kind delete clusters \$(kind get clusters)'"
    ssh root@$node docker rm $(docker ps -a -q)
    ssh root@$node docker rmi -f $(docker images)
    for runner in  "${RUNNER_CONTAINERS[@]}"; do
        ssh root@$node docker exec $runner "rm -rf /tmp/* || true"
    done
done
