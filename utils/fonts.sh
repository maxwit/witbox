#!/bin/sh

if [ $# -gt 0 ]; then
	fontdir=$1
else
	fontdir=`mktemp -d`
	SERVER=192.168.1.1
	#SERVER=conke.oicp.net

	wget -r -l 1 -A ttf,ttc,TTF,TTC -P $fontdir --cut-dirs=9 http://$SERVER/pub/utils/fonts/
	# FIXME
	fontdir=$fontdir/$SERVER
fi

sudo mkdir -vp /usr/share/fonts/truetype/ && \
sudo cp -v $fontdir/* /usr/share/fonts/truetype/ && \
echo && \
sudo fc-cache -v -f

echo
