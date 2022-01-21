#!/bin/bash

RUNNERS=(
    139.178.94.45)

for node in "${!RUNNERS[@]}"; do
    ssh root@${RUNNERS[$node]} "sudo apt-add-repository contrib"
    ssh root@${RUNNERS[$node]} "sudo apt update && sudo apt -y install git wget curl unzip qemu-kvm libvirt-daemon  bridge-utils virtinst libvirt-daemon-system virt-top libguestfs-tools libosinfo-bin  qemu-system virt-manager linux-headers-\$(uname -r) linux-image-amd64 spl kmod"
    #ssh root@${RUNNERS[$node]} "sudo apt install -y zfsutils-linux zfs-dkms zfs-zed"
    #ssh root@${RUNNERS[$node]} "sudo modprobe zfs && sudo apt -f install"
    #ssh root@${RUNNERS[$node]} "echo 'zfs' | sudo tee -a /etc/modules-load.d/zfs.conf"
    TER_VER=`curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1'`
    ssh root@${RUNNERS[$node]} "wget https://releases.hashicorp.com/terraform/${TER_VER}/terraform_${TER_VER}_linux_amd64.zip && unzip terraform_${TER_VER}_linux_amd64.zip && sudo mv terraform /usr/local/bin/"
    ssh root@${RUNNERS[$node]} "sudo modprobe vhost_net && sudo systemctl start libvirtd && sudo systemctl enable libvirtd && echo vhost_net | sudo tee -a /etc/modules && echo 'security_driver = \"none\"' | sudo tee -a /etc/libvirt/qemu.conf && systemctl restart libvirtd"
    ssh root@${RUNNERS[$node]} "sudo ln -s /usr/bin/genisoimage /usr/bin/mkisofs"
#    ssh root@${RUNNERS[$node]} "sudo virsh pool-define-as default dir - - - - '/guest_images' && sudo virsh pool-build default && sudo virsh pool-start default"
    ssh root@${RUNNERS[$node]} 'sudo sed -i "/net.ipv4.ip_forward=1/ s/# *//" /etc/sysctl.conf'
    ssh root@${RUNNERS[$node]} 'sudo sed -i "/net.ipv6.conf.all.forwarding=1/ s/# *//" /etc/sysctl.conf'
    ssh root@${RUNNERS[$node]} 'sudo sysctl -p'
#    ssh root@${RUNNERS[$node]} 'sudo apt install -y libvirt-daemon-driver-storage-zfs'
#    ssh root@${RUNNERS[$node]} 'sudo zpool create -f zfspool /dev/sdb'
#    ssh root@${RUNNERS[$node]} 'virsh pool-define-as --name zfsfilepool --source-name zfspool --type zfs'
#    ssh root@${RUNNERS[$node]} 'virsh pool-start zfsfilepool'
    scp ./qemu-images/my-build.qcow2 root@${RUNNERS[$node]}:/my-build.raw
    ssh root@${RUNNERS[$node]} 'qemu-img resize -f raw /my-build.raw +100G'
    ssh root@${RUNNERS[$node]} 'virsh pool-define-as poola logical - - /dev/sda libvirt_lvma \ /dev/libvirt_lvma'

    ssh root@${RUNNERS[$node]} 'virsh pool-define-as poolb logical - - /dev/sdb libvirt_lvmb \ /dev/libvirt_lvmb'

    ssh root@${RUNNERS[$node]} 'virsh pool-define-as poolc logical - - /dev/sdc libvirt_lvmc \ /dev/libvirt_lvmc'

    ssh root@${RUNNERS[$node]} 'virsh pool-define-as poold logical - - /dev/sdd libvirt_lvmd \ /dev/libvirt_lvmd'

    ssh root@${RUNNERS[$node]} 'virsh pool-define-as poold logical - - /dev/sdd libvirt_lvme \ /dev/libvirt_lvme'
    ssh root@${RUNNERS[$node]} 'virsh pool-build poola'
    ssh root@${RUNNERS[$node]} 'virsh pool-build poolb'
    ssh root@${RUNNERS[$node]} 'virsh pool-build poolc'
    ssh root@${RUNNERS[$node]} 'virsh pool-build poold'
    ssh root@${RUNNERS[$node]} 'virsh pool-build poole'

    ssh root@${RUNNERS[$node]} 'virsh pool-start poola'
    ssh root@${RUNNERS[$node]} 'virsh pool-start poolb'
    ssh root@${RUNNERS[$node]} 'virsh pool-start poolc'
    ssh root@${RUNNERS[$node]} 'virsh pool-start poold'
    ssh root@${RUNNERS[$node]} 'virsh pool-start poole'

    ssh root@${RUNNERS[$node]} 'virsh pool-autostart poola'
    ssh root@${RUNNERS[$node]} 'virsh pool-autostart poolb'
    ssh root@${RUNNERS[$node]} 'virsh pool-autostart poolc'
    ssh root@${RUNNERS[$node]} 'virsh pool-autostart poold'
    ssh root@${RUNNERS[$node]} 'virsh pool-autostart poole'
done
