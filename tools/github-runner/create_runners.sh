#!/bin/bash

TOKEN=$1

if [ -z "$1" ]; then
     echo "USAGE: sh ./create_runners.sh <GITHUB_RUNNER_TOKEN>"
     exit 1
fi


RUNNER_COUNT=0
RUNNER_IMAGE="conformance/github-runner:v2.316.1" # don't forget the v
docker pull $RUNNER_IMAGE
RUNNERS_PER_NODE=4
    until [ $RUNNERS_PER_NODE -eq 0 ]; do
        docker run -d --network host --restart always --name unh-runner$RUNNER_COUNT -e REPO_URL="https://github.com/cnti-testcatalog/testsuite" -e RUNNER_NAME="unhrunner$RUNNER_COUNT" -e RUNNER_TOKEN="$TOKEN" -e RUNNER_WORKDIR="/unh-runner-cnf-testsuite" -e LABELS="v1.0.0" -v /var/run/docker.sock:/var/run/docker.sock -v /runner-tmp/runner$RUNNER_COUNT:/tmp -v /github-runner-cnf-testsuite/cnf-testsuite/cnf-testsuite/tools:/docker-host-repo/tools -v /shared:/shared $RUNNER_IMAGE
        RUNNER_COUNT=$(($RUNNER_COUNT + 1))
        RUNNERS_PER_NODE=$(($RUNNERS_PER_NODE - 1))
    done
sudo chmod 777 /runner-tmp -R

