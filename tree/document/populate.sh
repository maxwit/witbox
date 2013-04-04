#!/bin/sh
#
# fixme: depend on user group?
#

populate()
{
	for dir in appdevel build cpio cpp cppstart cstart ds ebuild kernel ldm lexpert lstart pm sysarch web
	do
		git clone git@192.168.0.2:document/$dir
	done
}

case $USER in
conke|rouchel|jack|annie|tina|gavin)
	populate
	;;
*)
esac
