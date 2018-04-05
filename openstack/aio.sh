#!/usr/bin/env bash

# if [ -e /etc/redhat-release ]; then
#     yum install -y bzip2-devel libaio MariaDB-client MariaDB-devel MariaDB-shared
#     cat > /etc/yum.repos.d/mariadb.repo << __EOF__
# [mariadb]
# name = MariaDB
# baseurl = http://yum.mariadb.org/10.3/centos7-amd64
# gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
# gpgcheck=1
# __EOF__
# else
#     apt install -y build-essential libaio1 libdbd-mysql-perl libmariadbclient-dev mariadb-client
# fi || exit 1
#
# if [ ! -d /opt/openstack-ansible ]; then
#     git clone https://git.openstack.org/openstack/openstack-ansible \
#         /opt/openstack-ansible || exit 1
# fi

cd /opt/openstack-ansible && \
git checkout stable/queens || exit 1

export BOOTSTRAP_OPTS='bootstrap_host_data_disk_device=sdb'
# export ANSIBLE_ROLE_FETCH_MODE='galaxy'
scripts/bootstrap-ansible.sh || exit 1

# export SCENARIO='ceph'
scripts/bootstrap-aio.sh || exit 1

cd /opt/openstack-ansible/playbooks || exit 1

openstack-ansible setup-hosts.yml || exit 1
openstack-ansible setup-infrastructure.yml || exit 1
openstack-ansible setup-openstack.yml || exit 1

openstack-ansible -e galera_ignore_cluster_state=true galera-install.yml || exit 1
