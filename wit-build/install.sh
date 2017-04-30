#!/usr/bin/env bash

ETC="/etc/wit"

mkdir -p $ETC && \
cp -v wit-watch $ETC && \
cp -v wit-build /usr/bin/ || exit 1

if [ -e /etc/rc.local ]; then
	grep wit-watch /etc/rc.local || \
		sed -i "/^exit/i $ETC/wit-watch\n" /etc/rc.local || exit 1
else
	echo "Warning: /etc/rc.local does not exist!"
	exit 1
fi

echo "WitBuild installed successfully, enjoy!"
echo
