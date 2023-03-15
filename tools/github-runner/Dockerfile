FROM myoung34/github-runner:2.303.0-ubuntu-bionic

ARG CRYSTAL_VERSION=1.6.2
ARG CRYSTAL_URL=https://github.com/crystal-lang/crystal/releases/download

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg --output /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    sudo gpg --dearmor /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list && \
    chmod 644 /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod 644 /etc/apt/sources.list.d/github-cli.list

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
    ln -s /usr/bin/python3 /usr/bin/python

RUN wget -O /tmp/kustomize.tar.gz "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.1.3/kustomize_v4.1.3_linux_amd64.tar.gz" && \
    tar -xvf /tmp/kustomize.tar.gz -C /tmp && \
    chmod +x /tmp/kustomize && \
    mv /tmp/kustomize /usr/local/bin/

RUN curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.13.0/kind-$(uname)-amd64" && \
    chmod +x ./kind && \
    mv ./kind /usr/local/bin

RUN add-apt-repository ppa:git-core/ppa -y && \
    apt update && \
    apt install -y git

