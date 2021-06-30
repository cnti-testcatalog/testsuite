FROM conformance/crystal:0.35.1-llvm10-grep

RUN apk add --no-cache \
    ca-certificates \
# DOCKER_HOST=ssh://... -- https://github.com/docker/cli/pull/1014
    openssh-client

# set up nsswitch.conf for Go's "netgo" implementation (which Docker explicitly uses)
# - https://github.com/docker/docker-ce/blob/v17.09.0-ce/components/engine/hack/make.sh#L149
# - https://github.com/golang/go/blob/go1.9.1/src/net/conf.go#L194-L275
# - docker run --rm debian:stretch grep '^hosts:' /etc/nsswitch.conf
RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV DOCKER_VERSION 20.10.7
# TODO ENV DOCKER_SHA256
# https://github.com/docker/docker-ce/blob/5b073ee2cf564edee5adca05eee574142f7627bb/components/packaging/static/hash_files !!
# (no SHA file artifacts on download.docker.com yet as of 2017-06-07 though)

RUN set -eux; \
  \
  apkArch="$(apk --print-arch)"; \
  case "$apkArch" in \
    'x86_64') \
      url='https://download.docker.com/linux/static/stable/x86_64/docker-20.10.7.tgz'; \
      ;; \
    'armhf') \
      url='https://download.docker.com/linux/static/stable/armel/docker-20.10.7.tgz'; \
      ;; \
    'armv7') \
      url='https://download.docker.com/linux/static/stable/armhf/docker-20.10.7.tgz'; \
      ;; \
    'aarch64') \
      url='https://download.docker.com/linux/static/stable/aarch64/docker-20.10.7.tgz'; \
      ;; \
    *) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;; \
  esac; \
  \
  wget -O docker.tgz "$url"; \
  \
  tar --extract \
    --file docker.tgz \
    --strip-components 1 \
    --directory /usr/local/bin/ \
  ; \
  rm docker.tgz; \
  \
  dockerd --version; \
  docker --version

COPY modprobe.sh /usr/local/bin/modprobe
COPY docker-entrypoint.sh /usr/local/bin/

# https://github.com/docker-library/docker/pull/166
#   dockerd-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-generating TLS certificates
#   docker-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-setting DOCKER_TLS_VERIFY and DOCKER_CERT_PATH
# (For this to work, at least the "client" subdirectory of this path needs to be shared between the client and server containers via a volume, "docker cp", or other means of data sharing.)
ENV DOCKER_TLS_CERTDIR=/certs
# also, ensure the directory pre-exists and has wide enough permissions for "dockerd-entrypoint.sh" to create subdirectories, even when run in "rootless" mode
RUN mkdir /certs /certs/client && chmod 1777 /certs /certs/client
# (doing both /certs and /certs/client so that if Docker does a "copy-up" into a volume defined on /certs/client, it will "do the right thing" by default in a way that still works for rootless users)

# https://github.com/docker/docker/blob/master/project/PACKAGERS.md#runtime-dependencies
RUN set -eux; \
  apk add --no-cache \
    btrfs-progs \
    e2fsprogs \
    e2fsprogs-extra \
    ip6tables \
    iptables \
    openssl \
    shadow-uidmap \
    xfsprogs \
    xz \
# pigz: https://github.com/moby/moby/pull/35697 (faster gzip implementation)
    pigz \
  ; \
# only install zfs if it's available for the current architecture
# https://git.alpinelinux.org/cgit/aports/tree/main/zfs/APKBUILD?h=3.6-stable#n9 ("all !armhf !ppc64le" as of 2017-11-01)
# "apk info XYZ" exits with a zero exit code but no output when the package exists but not for this arch
  if zfs="$(apk info --no-cache --quiet zfs)" && [ -n "$zfs" ]; then \
    apk add --no-cache zfs; \
  fi

# TODO aufs-tools

# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
RUN set -eux; \
  addgroup -S dockremap; \
  adduser -S -G dockremap dockremap; \
  echo 'dockremap:165536:65536' >> /etc/subuid; \
  echo 'dockremap:165536:65536' >> /etc/subgid

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT 42b1175eda071c0e9121e1d64345928384a93df1

RUN set -eux; \
  wget -O /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; \
  chmod +x /usr/local/bin/dind

COPY dockerd-entrypoint.sh /usr/local/bin/

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]

ARG KUBECTL_VERSION="v1.21.1"
ARG KIND_VERSION="v0.11.1"
ARG HELM_VERSION="v3.1.1"

RUN apk update && \
    apk add curl bash findutils && \
    curl -Lso /usr/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x /usr/bin/kubectl && \
    curl -Lso /usr/bin/kind "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64" && \
    chmod +x /usr/bin/kind && \
    curl -Lso /tmp/helm.tar.gz "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    tar -xvf /tmp/helm.tar.gz && \
    mv ./linux-amd64/helm /usr/bin/helm

COPY kind-config.yaml /kind-config.yaml

EXPOSE 30001

RUN mv /usr/local/bin/dockerd-entrypoint.sh /entrypoint-original.sh
COPY entrypoint-wrapper.sh /usr/local/bin/dockerd-entrypoint.sh
COPY kind_node/node.tar.gz /node.tar.gz
