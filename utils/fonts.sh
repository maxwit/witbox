#!/bin/sh

TOP_DIR=$PWD
SERVER=192.168.0.1

wget -r -l 1 -A ttf,ttc,TTF,TTC -P $TOP_DIR --cut-dirs=9 http://$SERVER/pub/utility/fonts/

sudo cp $TOP_DIR/$SERVER/simsun.ttc /usr/share/fonts/truetype/
sudo cp $TOP_DIR/$SERVER/simhei.ttf /usr/share/fonts/truetype/
sudo fc-cache -f
