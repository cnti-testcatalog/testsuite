FROM crystallang/crystal:1.0.0-alpine

ARG CRYSTAL_VERSION=1.0.0
ARG CRYSTAL_URL=https://github.com/crystal-lang/crystal/releases/download

RUN apk add --update --no-cache --force-overwrite \
      gc-dev gcc gmp-dev libatomic_ops libevent-static \
      musl-dev pcre-dev yaml-static \
      libxml2-dev openssl-dev openssl-libs-static \
      tzdata yaml-dev zlib-static \
      make git \
      llvm10-dev llvm10-static g++

CMD ["/bin/sh"]
