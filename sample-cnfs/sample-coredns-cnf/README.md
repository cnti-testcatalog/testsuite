# Set up Sample CoreDNS CNF
./sample-cnfs/sample-coredns-cnf/readme.md
# Prerequistes
### Install helm
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
### Optional: Use a helm version manager
https://github.com/yuya-takeyama/helmenv
Check out helmenv into any path (here is ${HOME}/.helmenv)
```
${HOME}/.helmenv)
$ git clone https://github.com/yuya-takeyama/helmenv.git ~/.helmenv
```
Add ~/.helmenv/bin to your $PATH any way you like
```
$ echo 'export PATH="$HOME/.helmenv/bin:$PATH"' >> ~/.bash_profile
```
```
helmenv versions 
helmenv install <version 3.1?>
```

### core-dns installation into the K8s cluster
```
helm install coredns stable/coredns
```
### Pull down the helm chart code, untar it, and put it in the cnfs/coredns directory
```
cd sample-cnfs/sample-coredns-cnf
helm pull --untar stable/coredns
cd ../..
cp -a sample-cnfs/sample-coredns-cnf cnfs
```
### Create confromance config.yml based on cnf-conformance.html

Update or create a config.yml based on the example [cnf-conformance](sample-cnfs/sample-coredns-cnf/cnf-conformance.yml) config file for sample-coredns-cnf
```
---
helm_directory: cnfs/sample-coredns-cnf/coredns
install_script: cnfs/sample-coredns-cnf/install.sh
deployment_name: coredns-coredns
application_deployment_names: [coredns-coredns]
helm_chart: stable/coredns 
```
