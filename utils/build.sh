#!/bin/sh

TOP_PATH=$PWD
GIT_HOME="/home/git"
DOCUMENT_PATH="/maxwit/document"
ALL_PROJECT=`sudo ls $GIT_HOME/repositories/document`
DOCUMENT_PUB="/maxwit/share"
distr=`lsb_release -si | tr 'A-Z' 'a-z'`

mkdir $DOCUMENT_PUB

case $distr in
centos | fedora)
	sudo yum install inotify-tools incron

	touch root

	for project in ${ALL_PROJECT[@]}
	do
		echo "$GIT_HOME/repositories/document/$project/refs/heads IN_CLOSE_WRITE sh $TOP_PATH/document_build.sh \$@" >> root

		name=`echo $project|awk -F . '{print $1}'`
		if [ ! -e "$DOCUMENT_PATH/$name" ]; then
			git clone git@127.0.0.1:document/$name $DOCUMENT_PATH/$name
			if [ `ls $DOCUMENT_PATH/$name|wc -l` != 0 ]; then
				cd $DOCUMENT_PATH/$name
				make
				cp *.pdf $DOCUMENT_PUB
			fi
		fi
	done

	echo "$GIT_HOME/repositories/document IN_CREATE sh $TOP_PATH/add_watch.sh \$#" >> root

	sudo cp root /var/spool/incron/
	sudo service incrond restart
	;;
esac
