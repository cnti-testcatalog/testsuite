#!/bin/bash

RUNNERS=(
139.178.91.101)

VIPS=(
147.75.68.32/28)

for node in "${!RUNNERS[@]}"; do
    ssh root@${RUNNERS[$node]} "git clone https://github.com/cncf/cnf-testsuite.git /"
    ssh root@${RUNNERS[$node]} "cd /cnf-testsuite/ && git checkout github_vms && cd tools/github-runner/kvm/terraform && terraform init"
    ssh root@${RUNNERS[$node]} \"cd /cnf-testsuite/tools/github-runner/kvm/terraform && terraform apply -var="token=${TOKEN}" -var="elastic_ips=${VIPS[$node]}"\"
done

