FROM conformance/offline:latest

RUN apk update && apk add ca-certificates wget

RUN wget https://github.com/coredns/coredns/releases/download/v1.8.4/coredns_1.8.4_linux_amd64.tgz && \
    tar -xvf ./coredns_1.8.4_linux_amd64.tgz -C /tmp/ && \
    cp /tmp/coredns /usr/local/bin/
    
COPY entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh