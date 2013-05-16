#!/bin/sh
#
# configure NFS server
#

#MAXWIT_TOP=${HOME}/maxwit
MAXWIT_TOP="/maxwit/lablin/"

#grep "${MAXWIT_TOP}" /etc/exports > /dev/null 2>&1 || \
grep "${MAXWIT_TOP}" /etc/exports || \
{
	fexport="/tmp/exports"
	cp /etc/exports $fexport
	echo "# MaxWit NFS">> $fexport
	echo "${MAXWIT_TOP} *(rw,sync,no_subtree_check,no_root_squash)" >> $fexport
	sudo cp $fexport /etc
	#sudo exportfs -av
	sudo /etc/init.d/nfs-kernel-server restart
	echo
}
