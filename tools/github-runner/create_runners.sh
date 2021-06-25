#!/bin/bash

RUNNERS=(
    145.40.90.133
    136.144.55.87
    136.144.55.243
    139.178.69.151
    139.178.69.153
    139.178.68.167
    86.109.1.243)

# TOKEN=$(curl  -XPOST -H "authorization: token ${GITHUB_TOKEN}" https://api.github.com/repos/cncf/cnf-testsuite/actions/runners/registration-token | jq -r .token)

RUNNER_COUNT=0
for node in "${RUNNERS[@]}"; do
    ssh root@$node docker pull conformance/github-runner:latest
    RUNNERS_PER_NODE=10
    until [ $RUNNERS_PER_NODE -eq 0 ]; do
        ssh root@$node "docker run -d --network host --restart always --name github-runner$RUNNER_COUNT -e REPO_URL="https://github.com/cncf/cnf-testsuite" -e RUNNER_NAME="runner$RUNNER_COUNT" -e RUNNER_TOKEN="$TOKEN" -e RUNNER_WORKDIR="/github-runner-cnf-testsuite" -e RUNNER_GROUP="testsuite" -v /var/run/docker.sock:/var/run/docker.sock -v /shared:/shared conformance/github-runner:latest"
        RUNNER_COUNT=$(($RUNNER_COUNT + 1))
        RUNNERS_PER_NODE=$(($RUNNERS_PER_NODE - 1))
    done
done
