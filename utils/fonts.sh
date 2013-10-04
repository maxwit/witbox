#!/bin/sh

TOP_DIR=$PWD

sudo cp $TOP_DIR/simsun.ttc /usr/share/fonts/truetype/
sudo cp $TOP_DIR/simhei.ttf /usr/share/fonts/truetype/
sudo fc-cache -f
