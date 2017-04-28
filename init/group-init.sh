#!/bin/bash

if [ $UID != 0 ]; then
	echo "pls run as root!"
	exit
fi

groupadd devel
groupadd maxwit

for user in `ls /home`
do
	usermod -g devel -a -G maxwit $user
	groupdel $user
done

echo
