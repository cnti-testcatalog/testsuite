FROM debian:latest 

ENV CRI_VERSION="v1.17.0"
ENV CTR_VERSION="1.5.0"
ENV CONTAINER_RUNTIME_ENDPOINT=unix:///run/containerd/containerd.sock
ENV IMAGE_SERVICE_ENDPOINT=unix:///run/containerd/containerd.sock

RUN echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list
RUN apt update && apt install -y curl sysbench
RUN curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRI_VERSION}/crictl-${CRI_VERSION}-linux-amd64.tar.gz --output crictl-${CRI_VERSION}-linux-amd64.tar.gz
RUN tar zxvf crictl-$CRI_VERSION-linux-amd64.tar.gz -C /usr/local/bin
RUN rm -f crictl-$CRI_VERSION-linux-amd64.tar.gz

RUN curl -L https://github.com/containerd/containerd/releases/download/v${CTR_VERSION}/containerd-${CTR_VERSION}-linux-amd64.tar.gz --output containerd-${CTR_VERSION}-linux-amd64.tar.gz
RUN tar zxvf containerd-${CTR_VERSION}-linux-amd64.tar.gz -C /tmp/                                                                   
RUN mv /tmp/bin/ctr /usr/local/bin

 


