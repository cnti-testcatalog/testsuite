FROM docker:20.10.6-dind

ARG KUBECTL_VERSION="v1.21.1"
ARG KIND_VERSION="v0.11.1"

RUN apk update && \
    apk add curl bash && \
    curl -Lso /usr/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x /usr/bin/kubectl && \
    curl -Lso /usr/bin/kind "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64" && \
    chmod +x /usr/bin/kind

COPY kind-config.yaml /kind-config.yaml

EXPOSE 30001

RUN mv /usr/local/bin/dockerd-entrypoint.sh /entrypoint-original.sh
COPY entrypoint-wrapper.sh /usr/local/bin/dockerd-entrypoint.sh
