#!/bin/sh

build()
{
	repo=$1

	cd $HOME
	if [ -d $repo ];
		cd $repo
		git pull
	else
		git clone git@192.168.1.1:$repo.git $repo
		cd $repo
	fi

	case $repo in)
	document/*)
		cd $repo
		make

		pdf=''
		for fn in `ls *.pdf`
		do
			if [ chapter${fn#chapter} != $fn ]; then
				pdf="$pdf $fn"
			fi
		done

		cp $pdf /tmp/

		if [ -e $HOME/Dropbox ]; then
			mkdir -vp $HOME/Dropbox/$repo
			for fn in `ls *.pdf`
			do
				cp $pdf $HOME/Dropbox/$repo 
			done
		fi
		;;

	project/*)
		cd $repo
		make
		;;
	esac
}

path=${1#/home/git/repositories/}
path=(`echo $path | sed 's:/: :g'`)

repo=''

for dir in $path
do
	entry=${dir%.git}

	if [ -z $repo ]; then
		repo = $entry
	else
		repo=$repo/$entry
	fi

	if [ $entry.git = $dir ]; then
		build $repo
		break
	fi
done
