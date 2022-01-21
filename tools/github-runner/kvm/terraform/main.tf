variable "token" {
  type = string
}

variable "elastic_ips" {
  type = string
}

variable "index" {
    type = string
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
  name   = "debian.raw-${var.index}"
  source = "/my-build.raw"
  format = "raw"
  pool = "pool${var.index}"
}

data "template_file" "user_data" {
  template = <<EOF
#cloud-config
growpart:
  mode: auto
  devices: ['/']
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
      ExecStart=/bin/bash -c 'export REPO_URL="https://github.com/cncf/cnf-testsuite" ; export RUNNER_NAME="runner${var.index}" ; export RUNNER_TOKEN="${var.token}" ; export RUNNER_WORKDIR="/tmp/github-runner-cnf-testsuite" ; export LABELS="vm" ; cd /actions-runner ; /entrypoint.sh ./bin/Runner.Listener run --startuptype service'
EOF
}

resource "libvirt_cloudinit_disk" "cloud_init" {
  name           = "cloud-init${var.index}.iso"
  user_data      = "${data.template_file.user_data.rendered}"
  pool = "pool${var.index}"
}

resource "libvirt_volume" "volume" {
  name = "volume${var.index}"
  base_volume_id = "${libvirt_volume.os_image.id}"
  pool = "pool${var.index}"
}

resource "libvirt_domain" "runner" {
  name   = "runner${var.index}"
  memory = "20000"
  vcpu   = 4

  cloudinit = "${libvirt_cloudinit_disk.cloud_init.id}"

  network_interface {
    network_name = "${libvirt_network.vmbr0.name}"
  }

  disk {
    volume_id = "${libvirt_volume.volume.id}"
  }
}
