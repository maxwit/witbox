#!/bin/bash

instance=noble-test2
back_img=$HOME/Downloads/cloud-images/noble-server-cloudimg-amd64.img
# os_name=debianbookworm

keyfile="$HOME/.ssh/id_rsa"
temp="/tmp/user-data.yaml"

test -f $keyfile || ssh-keygen -f $keyfile -t rsa -N ''

read pubkey < $keyfile.pub

cat > $temp << _EOF_
#cloud-config

hostname: $instance

users:
  - name: $USER
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh-authorized-keys:
      - $pubkey

runcmd:
  - apt update
  - apt install -y avahi-daemon
_EOF_

virt-install \
  --name $instance \
  --vcpus 4 \
  --memory 4096 \
  --graphics spice \
  --video virtio \
  --accelerate \
  --disk backing_store=$back_img,size=40 \
  --osinfo ubuntujammy \
  --network bridge=virbr0 \
  --cloud-init user-data=/tmp/user-data.yaml \
  --import
