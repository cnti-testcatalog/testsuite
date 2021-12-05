FROM myoung34/github-runner:2.285.0-ubuntu-bionic

ARG CRYSTAL_VERSION=1.0.0
ARG CRYSTAL_URL=https://github.com/crystal-lang/crystal/releases/download

RUN wget -O crystal.deb "$CRYSTAL_URL/$CRYSTAL_VERSION/crystal_$CRYSTAL_VERSION-1_amd64.deb" --progress=dot:giga && \
    apt update && \
    apt install -y --no-install-recommends \
    git \
    libssl-dev \
    libxml2-dev \
    libyaml-dev \
    libgmp-dev \
    libz-dev \
    ./crystal.deb && \
    rm -rf /var/lib/apt/lists/*

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

RUN apt-get install apt-transport-https --yes && \
    curl https://baltocdn.com/helm/signing.asc | apt-key add - && \
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update && \
    apt-get install helm uuid-runtime && \
    rm /usr/bin/python && \
    ln -s /usr/bin/python3 /usr/bin/python

RUN wget -O /tmp/kustomize.tar.gz "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.1.3/kustomize_v4.1.3_linux_amd64.tar.gz" && \
    tar -xvf /tmp/kustomize.tar.gz -C /tmp && \
    chmod +x /tmp/kustomize && \
    mv /tmp/kustomize /usr/local/bin/

RUN curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.11.1/kind-$(uname)-amd64" && \
    chmod +x ./kind && \
    mv ./kind /usr/local/bin

RUN add-apt-repository ppa:git-core/ppa -y && \
    apt update && \
    apt install -y git

    
