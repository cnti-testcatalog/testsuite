#!/bin/bash

RUNNERS=(
    139.178.91.101)

for node in "${!RUNNERS[@]}"; do
    ssh root@${RUNNERS[$node]} "sudo apt update && sudo apt -y install git wget curl unzip qemu-kvm libvirt-daemon  bridge-utils virtinst libvirt-daemon-system virt-top libguestfs-tools libosinfo-bin  qemu-system virt-manager"
    TER_VER=`curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1'`
    ssh root@${RUNNERS[$node]} "wget https://releases.hashicorp.com/terraform/${TER_VER}/terraform_${TER_VER}_linux_amd64.zip && unzip terraform_${TER_VER}_linux_amd64.zip && sudo mv terraform /usr/local/bin/"
    ssh root@${RUNNERS[$node]} "sudo modprobe vhost_net && sudo systemctl start libvirtd && sudo systemctl enable libvirtd && echo vhost_net | sudo tee -a /etc/modules && echo 'security_driver = \"none\"' | sudo tee -a /etc/libvirt/qemu.conf && systemctl restart libvirtd"
    ssh root@${RUNNERS[$node]} "sudo ln -s /usr/bin/genisoimage /usr/bin/mkisofs"
    ssh root@${RUNNERS[$node]} "sudo virsh pool-define-as default dir - - - - '/guest_images' && sudo virsh pool-build default && sudo virsh pool-start default"
    ssh root@${RUNNERS[$node]} 'sudo sed -i "/net.ipv4.ip_forward=1/ s/# *//" /etc/sysctl.conf'
    ssh root@${RUNNERS[$node]} 'sudo sed -i "/net.ipv6.conf.all.forwarding=1/ s/# *//" /etc/sysctl.conf'
    ssh root@${RUNNERS[$node]} 'sudo sysctl -p'
    scp ./qemu-images/my-build.qcow2 root@${RUNNERS[$node]}:/my-build.qcow2
done
