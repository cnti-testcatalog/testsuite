FROM debian:latest 

ENV VERSION="v1.17.0"
ENV CONTAINER_RUNTIME_ENDPOINT=unix:///run/containerd/containerd.sock
ENV IMAGE_SERVICE_ENDPOINT=unix:///run/containerd/containerd.sock

RUN apt update && apt install -y curl
RUN curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-${VERSION}-linux-amd64.tar.gz --output crictl-${VERSION}-linux-amd64.tar.gz
RUN tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
RUN rm -f crictl-$VERSION-linux-amd64.tar.gz
 


