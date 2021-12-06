#!/bin/bash

RUNNERS=(
139.178.91.101)

VIPS=(
147.75.68.32/28)


RUNNER_COUNT=10
for node in "${!RUNNERS[@]}"; do
  git clone
        ssh root@${RUNNERS[$node]} "docker run -d --network host --restart always --name github-runner$RUNNER_COUNT -e REPO_URL="https://github.com/cncf/cnf-testsuite" -e RUNNER_NAME="runner$RUNNER_COUNT" -e RUNNER_TOKEN="$TOKEN" -e RUNNER_WORKDIR="/github-runner-cnf-testsuite" -e LABELS="v1.0.0" -v /var/run/docker.sock:/var/run/docker.sock -v /runner-tmp/runner$RUNNER_COUNT:/tmp -v /shared:/shared conformance/github-runner:v2.284.0"
        RUNNER_COUNT=$(($RUNNER_COUNT + 1))
        RUNNERS_PER_NODE=$(($RUNNERS_PER_NODE - 1))
    done
    ssh root@${RUNNERS[$node]} "docker network rm kind"
    ssh root@${RUNNERS[$node]} docker network create --driver bridge --subnet=${VIPS[$node]} --opt "com.docker.network.bridge.name"="kindbridge" --opt "com.docker.network.bridge.enable_ip_masquerade"="false" kind
    ssh root@${RUNNERS[$node]} sudo chmod 777 /runner-tmp -R
    # ssh root@${RUNNERS[$node]} "sudo apt update && sudo apt install -y bridge-utils"
   # ssh root@${RUNNERS[$node]} "sudo brctl addif kindbridge bond0"
done

