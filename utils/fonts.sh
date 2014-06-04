#!/bin/sh

TMP_DIR=`mktemp -d`
SERVER=192.168.1.1
#SERVER=conke.oicp.net

wget -r -l 1 -A ttf,ttc,TTF,TTC -P $TMP_DIR --cut-dirs=9 http://$SERVER/pub/utils/fonts/ && \
sudo mkdir -vp /usr/share/fonts/truetype/ && \
sudo cp -v $TMP_DIR/$SERVER/* /usr/share/fonts/truetype/ && \
rm -rf $TMP_DIR && \
sudo fc-cache -f
