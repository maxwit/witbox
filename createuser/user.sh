#!/bin/sh

while read full_name
do
	name=($full_name)
	user=`echo ${name[0]} | tr 'A-Z' 'a-z'`
	echo useradd -m -c "$full_name" -g web -G maxwit $user
	useradd -m -c "$full_name" -g web -G maxwit $user
	echo -e "maxwit\nmaxwit" | passwd $user
	sudo -i -u $user $PWD/keygen.sh
done < $1
