#!/bin/sh

osx_unlock()
{
	macosx="unlock-all-v120"
	unzip -u $macosx.zip -d /tmp/
	cd /tmp/$macosx/linux
	chmod +x *
	sudo ./install.sh
}

/usr/lib/vmware/bin/vmware-vmx-debug -version

for sn in `cat sn.cfg`
do
	sudo /usr/lib/vmware/bin/vmware-vmx-debug --new-sn $sn
	if [ $? = 0 ]; then
		echo "\"$sn\" is valid!"
		echo

		osx_unlock
		exit
	fi
done

echo "No correct SN found!"
