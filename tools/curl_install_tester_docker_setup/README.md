Curl Install Tester
---
Curl install tester is a docker setup designed to 

- have [prereqs](INSTALL.md#prereqs) already setup so that

- you can seemlessly test [curl install](INSTALL.md#curl-install) instructions 

## Usage:

```
# https://stackoverflow.com/questions/36075525/how-do-i-run-a-docker-instance-from-a-dockerfile
# in the curl_install_tester_docker_setup folder
# because the dockerfile is there

docker build -t curl_install_tester_docker_setup --target base .

docker run --rm -it curl_install_tester_docker_setup 

source <(curl https://raw.githubusercontent.com/cncf/cnf-conformance/master/curl_install.sh)

cd # to make sure you are in home dir

cnf-conformance setup

wget -O cnf-conformance.yml https://raw.githubusercontent.com/cncf/cnf-conformance/release-v0.7-beta1/example-cnfs/coredns/cnf-conformance.yml

cnf-conformance cnf_setup cnf-config=./cnf-conformance.yml
```



You can comment out parts of the dockerfile to test things like not having proper prereqs etc