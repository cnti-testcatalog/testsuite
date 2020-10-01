#!/bin/bash
ssh -o StrictHostKeyChecking=no -t root@$SSH_HOST GOROOT=/tmp/$TIME/go GOPATH=\$HOME/go PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH kind delete clusters $TIME
ssh -o StrictHostKeyChecking=no -t root@$SSH_HOST docker rm -f $TIME; ssh -o StrictHostKeyChecking=no -t root@$SSH_HOST rm -rf /tmp/$TIME
exit 1
