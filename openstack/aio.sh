#!/usr/bin/env bash

if [ ! -d /opt/openstack-ansible ]; then
    git clone https://git.openstack.org/openstack/openstack-ansible \
        /opt/openstack-ansible || exit 1
fi

cd /opt/openstack-ansible && \
git checkout stable/queens || exit 1

# # FIXME
# disks=(`fdisk -l | grep '^Disk /dev' | awk '{print $2}'`)
# rootd=`awk '$2=="/" {print $1}' /proc/mounts`
#
# if [ ${#disks[@]} -gt 1 ]; then
# 	for disk in ${disks[@]/:/}; do
# 		if [ ${rootd#$disk} == $rootd ]; then
# 			export BOOTSTRAP_OPTS="bootstrap_host_data_disk_device=${disk/\/dev\//}"
# 			break
# 		fi
# 	done
# fi
#
# echo "BOOTSTRAP_OPTS = $BOOTSTRAP_OPTS"

mkdir -vp ~/.pip
cat > ~/.pip/pip.conf << _EOF_
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/
[install]
trusted-host = mirrors.aliyun.com
_EOF_

export BOOTSTRAP_OPTS="bootstrap_host_ubuntu_repo=http://mirrors.aliyun.com/ubuntu/"
# export ANSIBLE_ROLE_FETCH_MODE='galaxy'

scripts/bootstrap-ansible.sh || exit 1

sed -i '/^lxc_image_cache_server_mirrors:/a \ \ - https://mirrors.tuna.tsinghua.edu.cn/lxc-images' \
    /etc/ansible/roles/lxc_hosts/defaults/main.yml || exit 1

# export SCENARIO='ceph'
scripts/bootstrap-aio.sh || exit 1

cd /opt/openstack-ansible/playbooks || exit 1

openstack-ansible setup-hosts.yml || exit 1
openstack-ansible setup-infrastructure.yml || exit 1
openstack-ansible setup-openstack.yml || exit 1

openstack-ansible -e galera_ignore_cluster_state=true galera-install.yml || exit 1
