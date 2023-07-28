# Setting up Falco for `non_root_user` test

The CNF Testsuite sets up Falco for the `non_root_user` test. But Falco requires drivers that are built for the specific OS kernel version.

To run the `non_root_user` test, please choose a prebuilt driver or a custom driver, and then proceed to configure the CNF Testsuite to specify the appropriate Falco configuration.

## Prebuilt Falco drivers

* Falco provides prebuilt drivers only for the 3 recent driver versions ([reference](https://github.com/falcosecurity/falco/issues/2488#issuecomment-1507479462))
* Availability of prebuilt drivers can be checked [here](https://download.falco.org/driver/site/index.html?lib=4.0.0%2Bdriver&target=debian&arch=x86_64&kind=ebpf).

## Building a custom driver

Falco maintains the [falcosecurity/driverkit](https://github.com/falcosecurity/driverkit) project to help build custom drivers. Please refer to the project's documentation to build custom Falco drivers for your Linux kernel version.

## Specifying a Falco driver to be used with the CNF Testsuite

The CNF Testsuite installs Falco 3.1.5. The testsuite allows specifying Helm CLI options for Falco's Helm chart installation using the `FALCO_HELM_OPTS` env var.

This option can be used to pass a YAML file that overrides Falco's Helm chart values, like below.

```shell
FALCO_HELM_OPTS="-f falco-values.yml" ./cnf-testsuite non_root_user
```

> This `FALCO_HELM_OPTS` needs to be set when running the `non_root_user` test via the workload command too.

Below is an example YAML file that overrides Falco Helm values to specify a custom-built ebpf driver.

```yaml
driver:
  enabled: true
  kind: ebpf
  ebpf:
    path: "/falco-driver/falco-ubuntu.o"
mounts:
  volumes:
    - name: "driver-fs"
      hostPath:
        path: "/falco-driver"

  volumeMounts:
    - mountPath: "/falco-driver"
      name: driver-fs
```

Please refer to the [Falco Helm chart's values file](https://github.com/falcosecurity/charts/blob/falco-3.1.5/falco/values.yaml) to see options that can be specified.
