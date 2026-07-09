#!/bin/bash

instance=bookworm-node1

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

virt-install --name $instance --memory 4096 --vcpus 4 --disk backing_store=$HOME/Downloads/cloud-images/debian-12-generic-amd64.qcow2,size=40 --os-variant detect=on,name=debianbookworm --network bridge=virbr0 --cloud-init user-data=/tmp/user-data.yaml --import
