#!/usr/bin/env bash

mkdir -p $HOME/projects && cd $HOME/projects

if [ ! -d kubespray ]; then
	git clone https://github.com/kubernetes-incubator/kubespray.git
fi

cd kubespray

rm -rf inventory/mycluster
cp -rfp inventory/sample inventory/mycluster

# FIXME
declare -a IPS=(192.168.20.126 192.168.20.127 192.168.20.138)
CONFIG_FILE=inventory/mycluster/hosts.ini python3 contrib/inventory_builder/inventory.py ${IPS[@]} || exit 1

ki=`mktemp`
cat > $ki << __END__
---
- hosts: all
  # remote_user: root
  tasks:
  - name: Remove swap from /etc/fstab
    # mount:
    #   path: swap
    #   fstype: swap
    lineinfile:
      dest: /etc/fstab
      regexp: '\s+none\s+swap\s'
      state: absent
  - name: Disable swap
    command: swapoff -a
    # when: ansible_swaptotal_mb > 0
  - name: Disable firewalld
    systemd:
      name: firewalld
      state: stopped
      enabled: False
    ignore_errors: True
__END__

ansible-playbook -u root -i inventory/mycluster/hosts.ini $ki || exit 1

rm $ki

# cat inventory/mycluster/group_vars/all.yml

sed -i.orig -e 's/.*\(ingress_nginx_enabled:\).*/\1 true/' \
	-e 's/.*\(efk_enabled:\).*/\1 true/' \
	-e 's/.*\(helm_enabled:\).*/\1 true/' \
	inventory/mycluster/group_vars/k8s-cluster.yml

ansible-playbook -u root -i inventory/mycluster/hosts.ini cluster.yml
