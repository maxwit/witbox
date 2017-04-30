#!/usr/bin/env bash

# fixme!!!
dist_dir="ubuntu-10.10"
src_list="sources.list"

grep "$dist_dir" /etc/apt/$src_list || \
{
	echo "deb http://192.168.0.2 $dist_dir main" > /tmp/$src_list
	echo >> /tmp/$src_list
	cat /etc/apt/$src_list >> /tmp/$src_list
	sudo mv -v /tmp/$src_list /etc/apt/$src_list

} 

# always update
sudo apt-get update
