#!/bin/bash

RUNNERS=(
	2001
	2002
	2003
	2004
        2005
        2006
        2007
        2008
        2009)

TOKEN=$1

if [ -z "$1" ]; then
     echo "USAGE: sh ./create_runners.sh <GITHUB_RUNNER_TOKEN>"
     exit 1
fi

eval $(ssh-agent)
ssh-add /home/pair/.vagrant.d/boxes/ubuntu-VAGRANTSLASH-mantic64/20240514.0.0/virtualbox/vagrant_insecure_key

RUNNER_COUNT=0
for node in "${!RUNNERS[@]}"; do
    export RUNNER_IMAGE="conformance/github-runner:v2.316.1" # don't forget the v
    ssh vagrant@127.0.0.1 -p ${RUNNERS[$node]} "sudo docker pull $RUNNER_IMAGE"
    RUNNERS_PER_NODE=2
    until [ $RUNNERS_PER_NODE -eq 0 ]; do
        ssh vagrant@127.0.0.1 -p ${RUNNERS[$node]} "sudo docker run -d --network host --restart always --name github-runner$RUNNER_COUNT -e REPO_URL="https://github.com/cnti-testcatalog/testsuite" -e RUNNER_NAME="runner$RUNNER_COUNT" -e RUNNER_TOKEN="$TOKEN" -e RUNNER_WORKDIR="/github-runner-cnf-testsuite" -e LABELS="v1.0.0" -v /var/run/docker.sock:/var/run/docker.sock -v /runner-tmp/runner$RUNNER_COUNT:/tmp -v /github-runner-cnf-testsuite/cnf-testsuite/cnf-testsuite/tools:/docker-host-repo/tools -v /shared:/shared $RUNNER_IMAGE"
        RUNNER_COUNT=$(($RUNNER_COUNT + 1))
        RUNNERS_PER_NODE=$(($RUNNERS_PER_NODE - 1))
    done
done
