#!/bin/bash

RUNNERS=(
    145.40.90.133
    136.144.55.87
    136.144.55.243
    139.178.69.151
    139.178.69.153
    139.178.68.167
    86.109.1.243)

VIPS=(
    147.75.68.32/28
    147.75.89.176/28
    147.75.108.64/28
    147.75.202.0/28
    147.75.202.80/28
    147.75.88.0/28
    147.75.202.112/28)


RUNNER_COUNT=0
for node in "${!RUNNERS[@]}"; do
    ssh root@${RUNNERS[$node]} "docker pull conformance/github-runner:latest"
    RUNNERS_PER_NODE=10
    until [ $RUNNERS_PER_NODE -eq 0 ]; do
        ssh root@${RUNNERS[$node]} "docker run -d --network host --restart always --name github-runner$RUNNER_COUNT -e REPO_URL="https://github.com/cncf/cnf-testsuite" -e RUNNER_NAME="runner$RUNNER_COUNT" -e RUNNER_TOKEN="$TOKEN" -e RUNNER_WORKDIR="/github-runner-cnf-testsuite" -e RUNNER_GROUP="testsuite" -v /var/run/docker.sock:/var/run/docker.sock -v /runner-tmp/runner$RUNNER_COUNT:/tmp -v /shared:/shared conformance/github-runner:latest"
        RUNNER_COUNT=$(($RUNNER_COUNT + 1))
        RUNNERS_PER_NODE=$(($RUNNERS_PER_NODE - 1))
    done
    ssh root@${RUNNERS[$node]} "docker network rm kind"
    ssh root@${RUNNERS[$node]} \"docker network create --driver bridge --subnet=${VIPS[$node]} --opt "com.docker.network.bridge.name"="kindbridge" --opt "com.docker.network.bridge.enable_ip_masquerade"="false" kind\"
    ssh root@${RUNNERS[$node]} "sudo apt update && sudo apt install -y bridge-utils"
    ssh root@${RUNNERS[$node]} "sudo brctl addif kindbridge bond0"
done

