FROM buildpack-deps:buster-curl

ENV KUBECTL_VERSION 1.19.2-00

ENV KIND_VERSION v0.9.0 

ENV HELM_VERSION v3.3.4
ENV HELM_FILE linux-amd64.tar.gz 
ENV HELM_SHA b664632683c36446deeb85c406871590d879491e3de18978b426769e43a1e82c
ENV HELM_URL https://get.helm.sh/helm-$HELM_VERSION-$HELM_FILE
ENV HELM_ASC https://github.com/helm/helm/releases/download/$HELM_VERSION/helm-$HELM_VERSION-$HELM_FILE.asc

ENV CRYSTAL_VERSION 0.35.1
ENV CRYSTAL_FILE crystal_$CRYSTAL_VERSION-1_amd64.deb
ENV CRYSTAL_URL https://github.com/crystal-lang/crystal/releases/download/$CRYSTAL_VERSION/$CRYSTAL_FILE

ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 19.03.13
ENV DOCKER_URL https://download.docker.com/linux/static/$DOCKER_CHANNEL/x86_64/docker-$DOCKER_VERSION.tgz

ENV GOLANG_VERSION 1.15.2
ENV GOLANG_FILE linux-amd64.tar.gz
ENV GOLANG_SHA b49fda1ca29a1946d6bb2a5a6982cf07ccd2aba849289508ee0f9918f6bb4552
ENV GOLANG_URL https://storage.googleapis.com/golang/go$GOLANG_VERSION.$GOLANG_FILE

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH
ENV PATH /usr/local/go/bin:$PATH

# Install Docker
RUN wget -O docker.tgz "$DOCKER_URL" --progress=dot:giga; 
RUN tar --strip-components 1 -C /usr/local/bin -xzf docker.tgz; \
    rm docker.tgz 

# Install Kubectl 
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -; \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list; \
    apt-get update ; \
    apt-get install -y kubectl=$KUBECTL_VERSION 

# Install Golang
RUN apt-get install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
		pkg-config 

RUN wget -O go.tgz.asc "$GOLANG_URL.asc" --progress=dot:giga; \
    wget -O go.tgz "$GOLANG_URL" --progress=dot:giga

RUN echo "$GOLANG_SHA *go.tgz" | sha256sum --strict --check -; \
	  export GNUPGHOME="$(mktemp -d)"; \
	  gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 'EB4C 1BFD 4F04 2F6D DDCC EC91 7721 F63B D38B 4796'; \
    gpg --batch --verify go.tgz.asc go.tgz; \
	  gpgconf --kill all; \
	  rm -rf "$GNUPGHOME" go.tgz.asc

RUN tar -C /usr/local -xzf go.tgz; \
    mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"; \
    rm go.tgz

# Install Crystal
RUN wget -O crystal.deb "$CRYSTAL_URL" --progress=dot:giga; 
RUN apt install -y --no-install-recommends \
    git \
    libssl-dev \
    libxml2-dev \
    libyaml-dev \
    libgmp-dev \
    libz-dev \
    ./crystal.deb \
	  && rm -rf /var/lib/apt/lists/*

# Install Helm
RUN wget -O helm.tgz.asc "$HELM_ASC" --progress=dot:giga; \
    wget -O helm.tgz "$HELM_URL" --progress=dot:giga

RUN echo "$HELM_SHA *helm.tgz" | sha256sum --strict --check -; \
	  export GNUPGHOME="$(mktemp -d)"; \
	  gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys '967F 8AC5 E221 6F9F 4FD2 70AD 92AA 783C BAAE 8E3B'; \
    gpg --batch --verify helm.tgz.asc helm.tgz; \
	  gpgconf --kill all; \
	  rm -rf "$GNUPGHOME" helm.tgz.asc

RUN tar --strip-components 1 -C /usr/local/bin -xzf helm.tgz; \
    rm helm.tgz

# Install Kind
RUN GO111MODULE="on" go get sigs.k8s.io/kind@$KIND_VERSION





