#!/usr/bin/env bash

function pip_safe_install
{
    while [ true ]; do
        pip install -U $@ && break
    done
}

# FIXME
# kolla_mode='pip' # or git
network_interface="ens33"
kolla_internal_vip_address="192.168.31.222"
neutron_external_interface="ens38"
openstack_release="pike"

if [ $UID != 0 ]; then
    echo "pls run as root!"
    exit 1
fi

if [ -e /etc/os-release ]; then
    . /etc/os-release
    os_type=$ID
    os_name=$NAME
    os_version=$VERSION_ID # maybe none on ArchLinux
elif [ -e /etc/redhat-release ]; then
    dist=(`head -n 1 /etc/redhat-release`)
    os_type=`tr A-Z a-z <<< ${dist[0]}`
    os_name=${dist[0]}
    os_version=${dist[2]}
else
    echo -e "Unkown Linux distribution!\n"
    exit 1
fi

case "$os_type" in
centos)
    yum install -y epel-release && \
    yum install -y python-pip python-devel libffi-devel gcc openssl-devel libselinux-python || exit 1
    ;;

ubuntu)
    apt-get install -y python-pip python-dev libffi-dev gcc libssl-dev python-selinux || exit 1
    ;;

*)
    echo "unknown linux distribution '$os_type'!"
    exit 1
esac

pip_safe_install ansible

rm -rf /etc/kolla

if [ "$kolla_mode" == 'pip' ]; then
    pip_safe_install kolla-ansible

    if [ $os_type == 'centos' ]; then
        kolla_home=/usr/share/kolla-ansible
    else
        kolla_home=/usr/local/share/kolla-ansible
    fi
    cp -r $kolla_home/etc_examples/kolla /etc/kolla || exit 1
    grep 'BEGIN PRIVATE KEY' /etc/kolla/passwords.yml > /dev/null || kolla-genpwd || exit 1
else
    for repo in kolla kolla-ansible; do
        if [ ! -d $repo ]; then
            git clone https://github.com/openstack/$repo || exit 1
        fi
    done
    kolla_home=$PWD/kolla-ansible
    export PATH=$kolla_home/tools:$PATH
    cp -r $kolla_home/etc/kolla /etc/kolla && \
    pip_safe_install oslo.utils oslo.config || exit 1
    grep 'BEGIN PRIVATE KEY' /etc/kolla/passwords.yml > /dev/null || generate_passwords.py || exit 1
fi

sed -i -e "s/^#*\s*\(network_interface:\).*/\1 \"$network_interface\"/" \
    -e "s/^#*\s*\(neutron_external_interface:\).*/\1 \"$neutron_external_interface\"/" \
    -e "s/^#*\s*\(openstack_release:\).*/\1 \"$openstack_release\"/" \
    -e "s/^#*\s*\(kolla_internal_vip_address:\).*/\1 \"$kolla_internal_vip_address\"/" \
    /etc/kolla/globals.yml

    # -e "s/\(kolla_base_distro:\).*/\1 \"$os_type\"/" \

# [defaults]
# host_key_checking=False
# pipelining=True
# forks=100

# cp -v $kolla_home/ansible/inventory/* .
inventory=$kolla_home/ansible/inventory/all-in-one

kolla-ansible -i $inventory bootstrap-servers || exit 1

# cat > /etc/systemd/system/docker.service.d/kolla.conf << _EOF_
# [Service]
# MountFlags=shared
# ExecStart=
# ExecStart=/usr/bin/docker daemon \
#  -H fd:// \
#  --mtu 1400
# _EOF_

# cat > /etc/systemd/system/docker.service.d/kolla.conf << _EOF_
# [Service]
# MountFlags=shared
# ExecStart=
# ExecStart=/usr/bin/dockerd --mtu 1400
# _EOF_

# systemctl daemon-reload && \
# systemctl restart docker || exit 1

# kolla-ansible pull -i $inventory || exit 1

# kolla-build || exit 1

kolla-ansible -i $inventory prechecks || exit 1
kolla-ansible -i $inventory deploy || exit 1

kolla-ansible post-deploy || exit 1
. /etc/kolla/admin-openrc.sh || exit 1

pip_safe_install python-openstackclient python-glanceclient python-neutronclient

init-runonce
