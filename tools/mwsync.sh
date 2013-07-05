#!/bin/sh

WITDISK="/media/$USER/WitDisk"
LINUX_RELEASE_NAME=`lsb_release -is | tr A-Z a-z`
LINUX_RELEASE_VER=`lsb_release -cs`
MACHINE_TYPE=`uname -m`

SKIP_LIST=""

mount | grep -w "$WITDISK" || {
	echo "$WITDISK NOT mounted!"
	exit 1
}

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

SUBDIR="${LINUX_RELEASE_NAME}/${LINUX_RELEASE_VER}/${MACHINE_TYPE}"

SERVER_MNT="$WITDISK/archives/${SUBDIR}"
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
