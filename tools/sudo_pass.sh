#!/bin/sh

user=$1

if [ "$user" = "" ]; then
	echo "usage: xxx"
	exit 1
elif [ $USER != "root" ]; then
	echo "run as root or using sudo"
	exit 1
fi

grep "^${user}.*NOPASSWD" /etc/sudoers || \
{
	chmod +w /etc/sudoers
	cp /etc/sudoers /tmp/
	echo "$user ALL=(ALL) NOPASSWD: ALL" >> /tmp/sudoers
	cp /tmp/sudoers /etc
	chmod 440 /etc/sudoers
}
