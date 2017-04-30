#!/usr/bin/env bash

LINUX_RELEASE_NAME=`lsb_release -is | tr A-Z a-z`
LINUX_RELEASE_VER=`lsb_release -cs`
MACHINE_TYPE=`uname -m`

SKIP_LIST=""

WITPART=`awk '{print $2}' /proc/mounts | grep -w -i WitDisk`

if [ -z "$WITPART" ]; then
	echo "Please insert MaxWit Magic Disk!"
	exit 1
fi

case ${MACHINE_TYPE} in
i[3456]86)
	MACHINE_TYPE="i386"
	;;
x86_64)
	MACHINE_TYPE="amd64"
	;;
*)
	echo "SERVER NOT SUPPORT ${MACHINE_TYPE}"
	sudo umount ${SERVER_MNT} && rm -r ${SERVER_MNT}
	exit 1
	;;
esac

SUBDIR="${LINUX_RELEASE_NAME}/archives/${LINUX_RELEASE_VER}/${MACHINE_TYPE}"

SERVER_MNT="$WITPART/${SUBDIR}"
if [ ! -d "${SERVER_MNT}" ]; then
	echo "$SERVER_MNT does NOT exist!"
	sudo mkdir -vp $SERVER_MNT || exit 1
fi

LOCAL_PATH="/var/cache/apt/archives"

SKIP_LIST="lock"

xcp()
{
	for pkg in `ls $1`
	do
		if [ -z "$SKIP_LIST" -o $pkg != "$SKIP_LIST" ]; then
			if [ ! -e $2/${pkg} ]; then
				sudo cp -v $1/${pkg} $2
			fi
		else
			echo "Skipping \"$pkg\""
		fi
	done
}

xcp ${LOCAL_PATH} ${SERVER_MNT}
xcp ${SERVER_MNT} ${LOCAL_PATH}

sync
echo "Done."
