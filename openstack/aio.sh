#!/usr/bin/env bash

if [ ! -d /opt/openstack-ansible ]; then
    git clone https://git.openstack.org/openstack/openstack-ansible \
        /opt/openstack-ansible
fi

cd /opt/openstack-ansible

export BOOTSTRAP_OPTS="bootstrap_host_data_disk_device=sdb"
scripts/bootstrap-ansible.sh || exit 1

scripts/bootstrap-aio.sh || exit 1

cd /opt/openstack-ansible/playbooks || exit 1

openstack-ansible setup-hosts.yml || exit 1
openstack-ansible setup-infrastructure.yml || exit 1
openstack-ansible setup-openstack.yml || exit 1

openstack-ansible -e galera_ignore_cluster_state=true galera-install.yml || exit 1
