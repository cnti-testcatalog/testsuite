#!/bin/bash
#Rand File
openssl rand -writerand $HOME/.rnd
# Create CA private key
if [ ! -f ca-private.pem ]; then
      openssl ecparam -name prime256v1 -genkey -noout -out ca-private.pem
fi
    # Create CA public key
    openssl ec -in ca-private.pem -pubout -out ca-public.pem
    # Create self signed CA certificate
    openssl req -x509 -new -key ca-private.pem -days 365 -out ca.crt -subj "/CN=root.linkerd.cluster.local"

    # Create issuer private key
    if [ ! -f issuer-private.pem ]; then
          openssl ecparam -name prime256v1 -genkey -noout -out issuer-private.pem
    fi
        # Create issuer public key
        openssl ec -in issuer-private.pem -pubout -out issuer-public.pem
        # Create certificate signing request (BUG: the extension added here will be ignored by the signing)
        openssl req -new -key issuer-private.pem -out issuer.csr -subj "/CN=identity.linkerd.cluster.local" \
              -addext basicConstraints=critical,CA:TRUE
        # Create issuer cert by signing request
        openssl x509 \
            -extfile /etc/ssl/openssl.cnf \
            -extensions v3_ca \
            -req \
            -in issuer.csr \
            -days 180 \
            -CA ca.crt \
            -CAkey ca-private.pem \
            -CAcreateserial \
            -extensions v3_ca \
            -out issuer.crt
        rm issuer.csr
