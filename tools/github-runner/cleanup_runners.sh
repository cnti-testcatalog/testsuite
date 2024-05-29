#!/bin/bash

TOKEN=$1

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



if [ -z "$1" ]; then
   echo "USAGE: ./cleanup_runners.sh <GITHUB_RUNNER_TOKEN>"
   exit 1
fi

eval $(ssh-agent)
ssh-add /home/pair/.vagrant.d/boxes/ubuntu-VAGRANTSLASH-mantic64/20240514.0.0/virtualbox/vagrant_insecure_key

#TOKEN=$(curl  -XPOST -H "authorization: token ${GITHUB_TOKEN}" https://api.github.com/repos/cncf/cnf-testsuite/actions/runners/registration-token | jq -r .token)

for node in "${!RUNNERS[@]}"; do

    RUNNER_CONTAINERS=( $(ssh vagrant@127.0.0.1 -p ${RUNNERS[$node]} sudo docker ps --filter "name=github-runner" --format '{{.Names}}' | xargs) )
    ssh vagrant@127.0.0.1 -p ${RUNNERS[$node]} "sudo docker rm -f \$(docker ps -a -q)"
    ssh vagrant@127.0.0.1 -p ${RUNNERS[$node]} sudo docker exec ${RUNNER_CONTAINERS[1]} "sh -c 'kind delete clusters \$(kind get clusters)'"
    for runner in  "${RUNNER_CONTAINERS[@]}"; do
      ssh vagrant@127.0.0.1 -p ${RUNNERS[$node]} sudo docker exec $runner "/actions-runner/bin/Runner.Listener remove --token $TOKEN"
    done
    ssh vagrant@127.0.0.1 -p ${RUNNERS[$node]} "sudo systemctl stop docker"
    ssh vagrant@127.0.0.1 -p ${RUNNERS[$node]} "sudo rm -rf /var/lib/docker/*"
    ssh vagrant@127.0.0.1 -p ${RUNNERS[$node]} "sudo systemctl start docker"
    ssh vagrant@127.0.0.1 -p ${RUNNERS[$node]} "sudo rm -rf /tmp/*"
    ssh vagrant@127.0.0.1 -p ${RUNNERS[$node]} "sudo rm -rf /shared/"
    ssh vagrant@127.0.0.1 -p ${RUNNERS[$node]} "sudo rm -rf /runner-tmp/"
done
