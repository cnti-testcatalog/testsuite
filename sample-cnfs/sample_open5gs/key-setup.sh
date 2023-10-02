#!/bin/bash

openssl genpkey -algorithm X25519 > curve25519-1.key 
KEY_CURVE=$(cat curve25519-1.key)

openssl ecparam -name prime256v1 -genkey -conv_form compressed > secp256r1-2.key
KEY_SECP=$(cat secp256r1-2.key)

cat << EOF > ./configmap.yml
apiVersion: v1
kind: ConfigMap
metadata:
    name: key
data:
  curve: |-
    $KEY_CURVE

  secp: |-
    $KEY_SECP
EOF

sed -i '8,9s/^/    /' ./configmap.yml
sed -i '13,19s/^/    /' ./configmap.yml
