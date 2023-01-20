FROM ubuntu:jammy-20221130

RUN sed -i -e 's/^APT/# APT/' -e 's/^DPkg/# DPkg/' \
      /etc/apt/apt.conf.d/docker-clean && \
    apt update && \
    apt install wget nginx -y

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-amd64 /tini
RUN chmod +x /tini

ENTRYPOINT ["/tini", "--"]
CMD ["nginx", "-g", "daemon off;"]
