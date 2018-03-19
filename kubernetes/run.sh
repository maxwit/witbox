#!/usr/bin/env bash

mkdir -p $HOME/projects && cd $HOME/projects

if [ ! -d kubespray ]; then
	git clone https://github.com/kubernetes-incubator/kubespray.git
fi

cd kubespray

cp -rfp inventory/sample inventory/mycluster

# FIXME
declare -a IPS=(192.168.173.11 192.168.173.12 192.168.173.13)
CONFIG_FILE=inventory/mycluster/hosts.ini python3 contrib/inventory_builder/inventory.py ${IPS[@]} || exit 1

ki=`mktemp`
curl -fsSL -o $ki https://github.com/conke/witbox/raw/master/kubernetes/kube-init.yml
ansible-playbook -u root -i inventory/mycluster/hosts.ini $ki || exit 1
rm $ki

# cat inventory/mycluster/group_vars/all.yml

sed -i.orig -e 's/.*\(ingress_nginx_enabled:\).*/\1 true/' \
	-e 's/.*\(efk_enabled:\).*/\1 true/' \
	-e 's/.*\(helm_enabled:\).*/\1 true/' \
	inventory/mycluster/group_vars/k8s-cluster.yml

ansible-playbook -u root -i inventory/mycluster/hosts.ini cluster.yml
