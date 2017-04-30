#!/usr/bin/env bash

DLPATH="/etc/yum.repos.d/"
VERSION=`lsb_release -sr`

#sudo wget -P ${DLPATH} http://mirrors.sohu.com/help/fedora-sohu.repo
#sudo wget -P ${DLPATH} http://mirrors.sohu.com/help/fedora-updates-sohu.repo
#sudo wget -P ${DLPATH} http://mirrors.163.com/.help/fedora-163.repo
#sudo wget -P ${DLPATH} http://mirrors.163.com/.help/fedora-updates-163.repo
#sudo yum makecache
#
sudo rpm -ivh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-stable.noarch.rpm
sudo yum localinstall -y --nogpgcheck http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${VERSION}.noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${VERSION}.noarch.rpm

sudo yum install -y axel yum-plugin-fastestmirror
sudo yum update -y
#
#sudo yum -y install vim valgrind unrar thunderbird ibus-table ibus-pinyin RedHat-lsb compat-libstdc++-33 NetworkManager-devel python-gevent tracker-ui-tools qemu libpciaccess-devel xorg-x11-util-macros llvm-devel mtdev* mutt msmtp tftp tftp-server policycoreutils-gui mtd-utils mtd-utils-ubi ckermit stardict stardict-dic-zh_CN stardict-dic-en samba
#
#sudo yum install -y gstreamer-plugins-good gstreamer-plugins-bad gstreamer-plugins-ugly libtunepimp-extras-freeworld xine-lib-extras-freeworld
#sudo yum install -y smplayer vlc ffmpeg ffmpeg-libs gstreamer-ffmpeg libmatroska xvidcore
#
#sudo yum -y install flash-plugin gnash
