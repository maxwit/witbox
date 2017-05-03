
# TODO:
# update repo source with mirrors
# vmware gfx driver like vmwgfx in Linux
# gnome3 support

pkg_list+=(bash sudo vim)

chpass -s /usr/loca/bin/bash [$user]

dbus-uuidgen > /etc/machine-id

pkg install -y open-vm-tools
