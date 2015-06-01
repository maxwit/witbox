#!/bin/sh

/usr/lib/vmware/bin/vmware-vmx-debug -version

for sn in `cat sn.cfg`
do
	sudo /usr/lib/vmware/bin/vmware-vmx-debug --new-sn $sn
	if [ $? = 0 ]; then
		echo "\"$sn\" is valid!"
		echo
		exit
	fi
done

echo "No correct SN found!"
