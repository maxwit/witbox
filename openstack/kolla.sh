#!/usr/bin/env bash

function pip_safe_install
{
    while [ true ]; do
        pip install -U $@ && break
    done
}

# FIXME
# kolla_mode='pip' # or git
openstack_release="pike"

ifx=(`ip a | grep -owe "ens[0-9]\+:" | sed 's/://g'`)
if [ ${#ifx[@]} == 0 ]; then
  echo "error: NIC count = ${#ifx[@]}!"
  exit 1
fi

# FIXME: customization
network_interface="${ifx[0]}"
if [ ${#ifx[@]} == 1 ]; then
  neutron_external_interface="${ifx[0]}"
else
  neutron_external_interface="${ifx[1]}"
fi

vip=`ip a s dev $network_interface | grep -e "inet\s.*brd" | awk '{print $2}' | awk -F '/' '{print $1}'`
vip=${vip%.*}.234
kolla_internal_vip_address="$vip"

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
    yum install -y python-pip python-devel libffi-devel gcc git openssl-devel libselinux-python || exit 1
    ;;
ubuntu)
    apt-get install -y python-pip python-dev libffi-dev gcc git libssl-dev python-selinux || exit 1
    ;;
*)
    echo "unknown linux distribution '$os_type'!"
    exit 1
esac

pip_safe_install pip
pip_safe_install ansible
pip_safe_install python-openstackclient python-glanceclient python-neutronclient

if [ "$kolla_mode" == 'pip' ]; then
    pip_safe_install kolla-ansible
    if [ $os_type == 'centos' ]; then
        kolla_home=/usr/share/kolla-ansible
    else
        kolla_home=/usr/local/share/kolla-ansible
    fi
    [ -d /etc/kolla ] || cp -r $kolla_home/etc_examples/kolla /etc/kolla || exit 1
    grep 'BEGIN PRIVATE KEY' /etc/kolla/passwords.yml > /dev/null || kolla-genpwd || exit 1
else
    for repo in kolla kolla-ansible; do
        if [ ! -d $repo ]; then
            git clone https://github.com/openstack/$repo || exit 1
        fi
    done
    kolla_home=$PWD/kolla-ansible
    export PATH=$kolla_home/tools:$PATH
    [ -d /etc/kolla ] || cp -r $kolla_home/etc/kolla /etc/kolla || exit 1
    grep 'BEGIN PRIVATE KEY' /etc/kolla/passwords.yml > /dev/null || generate_passwords.py || exit 1
fi

sed -i -e "s/^#*\s*\(network_interface:\).*/\1 \"$network_interface\"/" \
    -e "s/^#*\s*\(neutron_external_interface:\).*/\1 \"$neutron_external_interface\"/" \
    -e "s/^#*\s*\(kolla_internal_vip_address:\).*/\1 \"$kolla_internal_vip_address\"/" \
    -e "s/^#*\s*\(openstack_release:\).*/\1 \"$openstack_release\"/" \
    /etc/kolla/globals.yml

    # -e "s/\(kolla_base_distro:\).*/\1 \"$os_type\"/" \

# [defaults]
# host_key_checking=False
# pipelining=True
# forks=100

# cp -v $kolla_home/ansible/inventory/* .
inventory=$kolla_home/ansible/inventory/all-in-one

for ((i=0; i<3; i++)); do
    kolla-ansible -i $inventory bootstrap-servers && break
done || exit 1

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

for ((i=0; i<3; i++)); do
    kolla-ansible -i $inventory prechecks && break
done || exit 1

for ((i=0; i<3; i++)); do
    kolla-ansible -i $inventory deploy && break
done || exit 1

for ((i=0; i<3; i++)); do
    kolla-ansible post-deploy && break
done || exit 1

# while [ true ]; do
#     netstat -nptl | grep "$kolla_internal_vip_address:80" && break
#     sleep 1
# done
#
# . /etc/kolla/admin-openrc.sh || exit 1
# init-runonce
