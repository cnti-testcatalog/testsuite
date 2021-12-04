variable "token" {
  type = string
}

variable "elastic_ips" {
  type = string
}

variable "runner_count" {
    type = number
    default = 10
  }


terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
    uri = "qemu:///system"
}

resource "libvirt_network" "vmbr0" {
  name = "vmbr0"
  mode = "route"
  bridge = "vmbr0"
  addresses = ["${var.elastic_ips}"]
  dns {
    enabled = true
  }
}

resource "libvirt_volume" "os_image" {
  name   = "debian.qcow2"
  source = "../qemu-images/my-build.qcow2"
  format = "qcow2"
}

resource "libvirt_volume" "volume" {
  name = "volume-${count.index}"
  base_volume_id = "${libvirt_volume.os_image.id}"
  count = "${var.runner_count}"
}

data "template_file" "user_data" {
  template = <<EOF
#cloud-config
runcmd:
  - [ systemctl, start, runner ]
write_files:
  - path: /etc/systemd/system/runner.service
    content: |
      [Unit]
      Description=Github Runner
      After=network-online.target
      Requires=network-online.target
      [Service]
      ExecStartPre=/bin/bash -c "while true; do ping -c1 www.google.com > /dev/null && break; done"
      ExecStart=/bin/bash -c 'export REPO_URL="https://github.com/cncf/cnf-testsuite" ; export RUNNER_NAME="foo-runner" ; export RUNNER_TOKEN="${var.token}" ; export RUNNER_WORKDIR="/tmp/github-runner-cnf-testsuite" ; cd /actions-runner ; /entrypoint.sh ./bin/Runner.Listener run --startuptype service'
EOF
}

resource "libvirt_cloudinit_disk" "cloud_init" {
  name           = "cloud-init.iso"
  user_data      = "${data.template_file.user_data.rendered}"
}

resource "libvirt_domain" "test" {
  name   = "runner-${count.index}"
  memory = "512"
  vcpu   = 1

  cloudinit = "${libvirt_cloudinit_disk.cloud_init.id}"

  network_interface {
    network_name = "${libvirt_network.vmbr0.name}"
  }

  disk {
    volume_id = element(libvirt_volume.volume.*.id, count.index)
  }

  count = "${var.runner_count}"
}
