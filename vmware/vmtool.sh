#!/usr/bin/env bash

mkdir -p ~/build
cd ~/build

tar xf /media/$USER/VMware\ Tools/VMwareTools-9.9.2-2496486.tar.gz
cd vmware-tools-distrib

tar xf lib/modules/source/vmhgfs.tar
sed -i 's/d_alias) {/d_u.d_alias) {/' vmhgfs-only/inode.c
tar cf lib/modules/source/vmhgfs.tar vmhgfs-only

sudo ./vmware-install.pl -d
