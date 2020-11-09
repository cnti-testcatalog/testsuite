FROM crystallang/crystal:0.35.1

ARG VERSION=v3.2.4
ARG FILENAME=helm-${VERSION}-linux-amd64.tar.gz
ARG KUBECTL=v1.18.4

RUN apt update && apt install -y wget curl 

RUN curl -L https://get.helm.sh/${FILENAME} | tar zxv -C /tmp
RUN mv /tmp/linux-amd64/helm /usr/local/bin/
RUN helm repo add stable https://charts.helm.sh/stable

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBECTL/bin/linux/amd64/kubectl
RUN mv ./kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

WORKDIR /cnf-conformance
