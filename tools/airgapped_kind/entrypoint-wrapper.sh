#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

KIND_NODE_IMAGE="conformance/node:v1.21.1"

# Startup Docker daemon and wait for it to be ready.
/entrypoint-original.sh &
while ! docker ps -q ; do sleep 1; done

if ! [ -f "/cache" ]; then

  echo "Setting up KIND cluster"

  docker load -i /node.tar.gz

  kind create cluster --config=/kind-config.yaml --image=${KIND_NODE_IMAGE} --wait=900s
fi

exec "$@"
