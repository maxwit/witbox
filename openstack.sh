#!/usr/bin/env bash

# FIXME
network_interface="ens33"
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
    yum install -y epel-release
    yum install -y git python-pip python-devel libffi-devel gcc openssl-devel libselinux-python
    ;;

ubuntu)
    apt-get install -y git python-pip python-dev libffi-dev gcc libssl-dev python-selinux
    ;;

*)
    echo "unknown linux distribution '$os_type'!"
    exit 1
esac

for p in pip ansible kolla-ansible; do
    while [ true ]; do
        pip install -U $p && break
    done
done

# pip install -U pip
# pip install -U ansible

# # FIXME
# pip install kolla-ansible

# cd $HOME?
for repo in kolla kolla-ansible; do
    if [ ! -d $repo ]; then
        git clone https://github.com/openstack/$repo || exit 1
    fi
done

rm -rf /etc/kolla
cp -r kolla-ansible/etc/kolla /etc/kolla

cp -v kolla-ansible/ansible/inventory/* .

sed -i -e "s/^#\s*\(network_interface:\).*/\1 \"$network_interface\"/" \
    -e "s/^#\s*\(neutron_external_interface:\).*/\1 \"$neutron_external_interface\"/" \
    -e "s/\(openstack_release:\)/\1 \"$openstack_release\"/" \
    /etc/kolla/globals.yml

    # -e "s/\(kolla_base_distro:\).*/\1 \"$os_type\"/" \

kolla-genpwd

./kolla-ansible/tools/kolla-ansible -i all-in-one bootstrap-servers || exit 1

# cat > /etc/systemd/system/docker.service.d/kolla.conf << _EOF_
# [Service]
# MountFlags=shared
# ExecStart=
# ExecStart=/usr/bin/docker daemon \
#  -H fd:// \
#  --mtu 1400
# _EOF_

cat > /etc/systemd/system/docker.service.d/kolla.conf << _EOF_
[Service]
MountFlags=shared
ExecStart=
ExecStart=/usr/bin/dockerd --mtu 1400
_EOF_

systemctl daemon-reload && \
systemctl restart docker || exit 1

./kolla-ansible/tools/kolla-ansible pull -i all-in-one || exit 1

# kolla-build || exit 1

./kolla-ansible/tools/kolla-ansible prechecks -i all-in-one || exit 1
./kolla-ansible/tools/kolla-ansible deploy -i all-in-one || exit 1
./kolla-ansible/tools/kolla-ansible post-deploy || exit 1

. /etc/kolla/admin-openrc.sh

./kolla-ansible/tools/init-runonce