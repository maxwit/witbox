#!/bin/bash

repo=$1
repo=${repo#/home/git/repositories/}
repo=${repo%.git/refs/heads}

clone_repo()
{
	cd $1

	if [ -d $2 ]; then
		cd $2
		git pull
	else
		git clone git@192.168.1.1:$2.git $2
		cd $2
	fi
}

case $repo in
document/*|book/*|slide/*|testing/*)
	clone_repo $HOME/Documents $repo

	make

	if [ -e $HOME/Dropbox ]; then
		dest=$HOME/Dropbox/$repo
	else
		dest=/tmp/$repo
	fi

	mkdir -p $dest
	cp -v *.pdf $dest
	;;

project/*)
	clone_repo $HOME $repo
	make
	;;
esac
