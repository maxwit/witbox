#!/bin/sh

TOP_PATH=$PWD
GIT_HOME="/home/git"
DOCUMENT_PATH="/maxwit/document"
ALL_PROJECT=`sudo ls $GIT_HOME/repositories/document`
DOCUMENT_PUB="/maxwit/share"
SOURCE_PATH="/maxwit/source"
BUILD_PATH="/maxwit/build"
distr=`lsb_release -si | tr 'A-Z' 'a-z'`
WGET="wget -c -P $SOURCE_PATH"

sudo useradd texbuild
echo "please input texbuild passwd:"
sudo passwd texbuild

mkdir $DOCUMENT_PUB

case $distr in
fedora)
	sudo yum install inotify-tools incron
	;;

centos)
	INOTIFY_VER="3.14"
	INCRON_VER="0.5.10"

	if [ ! -e $SOURCE_PATH/inotify-tools-${INOTIFY_VER}.tar.gz ]; then
		$WGET http://cloud.github.com/downloads/rvoicilas/inotify-tools/inotify-tools-${INOTIFY_VER}.tar.gz
	fi

	if [ ! -e $SOURCE_PATH/incron-${INCRON_VER}.tar.gz ]; then
		$WGET http://inotify.aiken.cz/download/incron/incron-${INCRON_VER}.tar.gz
	fi

	if [ ! -e $BUILD_PATH/inotify-tools-${INOTIFY_VER} ]; then
		cd $BUILD_PATH
		tar xvf $SOURCE_PATH/inotify-tools-${INOTIFY_VER}.tar.gz
		cd inotify-tools-${INOTIFY_VER}
		./configure
		make
		sudo make install
	fi

	if [ ! -e $BUILD_PATH/incron-${INCRON_VER} ]; then
		cd $BUILD_PATH
		tar xvf $SOURCE_PATH/incron-${INCRON_VER}.tar.gz
		cd incron-${INCRON_VER}
		./configure
		make
		sudo make install
	fi

	;;
esac

	if [ ! -e "$DOCUMENT_PATH/texbuild" ]; then
		sudo su texbuild -c "git clone git@127.0.0.1:document/texbuild $DOCUMENT_PATH/texbuild"
	fi

	touch root
	for project in ${ALL_PROJECT[@]}
	do
		name=`echo $project|awk -F . '{print $1}'`
		if [ "$name" = "interview" ]; then
			continue
		fi

		cd $TOP_PATH
		echo "$GIT_HOME/repositories/document/$project/refs/heads IN_CLOSE_WRITE sh $TOP_PATH/document_build.sh \$@" >> root

		if [ ! -e "$DOCUMENT_PUB/$name" ]; then
			mkdir $DOCUMENT_PUB/$name
		fi

		if [ ! -e "$DOCUMENT_PATH/$name" ]; then
			sudo su texbuild -c "git clone git@127.0.0.1:document/$name $DOCUMENT_PATH/$name"
		fi

		cd $DOCUMENT_PATH/$name
		sudo su texbuild -c "git pull"

		if [ `ls $DOCUMENT_PATH/$name|wc -l` != 0 ]; then
			make
			cp *.pdf $DOCUMENT_PUB/$name
		fi
	done

	cd $TOP_PATH
	echo "$GIT_HOME/repositories/document IN_CREATE sh $TOP_PATH/add_watch.sh \$#" >> root

	sudo cp root /var/spool/incron/

	if [ "$distr" = "centos" ]; then
		sudo `which incrond` start
	else
		sudo service incrond restart
	fi
exit
