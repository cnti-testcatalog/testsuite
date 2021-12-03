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

resource "libvirt_volume" "debian" {
  name   = "debian.qcow2"
  source = "../qemu-images/my-build.qcow2"
#  source = "https://github.com/multani/packer-qemu-debian/releases/download/10.0.0-1/debian-10.0.0-1.qcow2"
  format = "qcow2"
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
      ExecStart=/bin/bash -c 'export REPO_URL="https://github.com/cncf/cnf-testsuite" ; export RUNNER_NAME="foo-runner" ; export RUNNER_TOKEN="" ; export RUNNER_WORKDIR="/tmp/github-runner-cnf-testsuite" ; cd /actions-runner ; /entrypoint.sh ./bin/Runner.Listener run --startuptype service'
EOF
}

resource "libvirt_cloudinit_disk" "cloud_init" {
  name           = "cloud-init.iso"
  user_data      = "${data.template_file.user_data.rendered}"
}

resource "libvirt_domain" "test" {
  name   = "test"
  memory = "512"
  vcpu   = 1

  cloudinit = "${libvirt_cloudinit_disk.cloud_init.id}"

  network_interface {
    network_name = "default"
  }

  disk {
    volume_id = "${libvirt_volume.debian.id}"
  }
}
