#!/usr/bin/env bash

# Copy ``inventory/sample`` as ``inventory/mycluster``
cp -rfp inventory/sample inventory/mycluster

# Update Ansible inventory file with inventory builder
declare -a IPS=(192.168.18.21 192.168.18.22 192.168.18.23)
CONFIG_FILE=inventory/mycluster/hosts.ini python3 contrib/inventory_builder/inventory.py ${IPS[@]} || exit 1

# Review and change parameters under ``inventory/mycluster/group_vars``
# cat inventory/mycluster/group_vars/all.yml
# cat inventory/mycluster/group_vars/k8s-cluster.yml

# Deploy Kubespray with Ansible Playbook
ansible-playbook -i inventory/mycluster/hosts.ini cluster.yml
