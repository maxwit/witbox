#!/bin/sh

kernel_pkg="linux-generic linux-headers-generic"

arch=`uname -m`
if [ "$arch" != "x86_64" ]; then
	kernel_pkg=`echo $kernel_pkg | sed -e 's/\s\+/-pae /g' -e 's/$/-pae/'`
fi

sudo apt-get install -y ${kernel_pkg} || \
{
	echo "$0: update failed!"
	exit 1
}
