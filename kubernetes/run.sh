#!/usr/bin/env bash

mkdir -p $HOME/projects && cd $HOME/projects

if [ ! -d kubespray ]; then
	git clone https://github.com/kubernetes-incubator/kubespray.git
fi

cd kubespray

cp -rfp inventory/sample inventory/mycluster

# FIXME
declare -a IPS=(192.168.18.11 192.168.18.12 192.168.18.13)
CONFIG_FILE=inventory/mycluster/hosts.ini python3 contrib/inventory_builder/inventory.py ${IPS[@]} || exit 1

# cat inventory/mycluster/group_vars/all.yml

sed -i.orig -e 's/.*\(ingress_nginx_enabled:\).*/\1 true/' \
	-e 's/.*\(efk_enabled:\).*/\1 true/' \
	-e 's/.*\(helm_enabled:\).*/\1 true/' \
	inventory/mycluster/group_vars/k8s-cluster.yml

ansible-playbook -u root -i inventory/mycluster/hosts.ini cluster.yml
