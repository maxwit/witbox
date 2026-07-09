#!/usr/bin/env bash

#path_to_lablin_arch=${HOME}/Pictures
cp -v lablin_arch.jpg ${HOME}/Pictures

#sed "s:path_to_lablin_arch:${path_to_lablin_arch}:" backgrounds.xml > ~/.gnome2/backgrounds.xml
#mkdir -vp ~/.gconf/desktop/gnome/background
#sed "s:path_to_lablin_arch:${path_to_lablin_arch}:" gconf.xml > ~/.gconf/desktop/gnome/background/%gconf.xml

sed "s:<filename>.*</filename>:<filename>$HOME/Pictures/lablin_arch.jpg</filename>:" $HOME/.config/gnome-control-center/backgrounds/last-edited.xml
