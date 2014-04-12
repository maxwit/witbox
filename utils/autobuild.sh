#!/bin/bash

TOP=$HOME/document

last='none'
inotifywait -mrq -e modify,create,delete $TOP --format %w%f --exclude .git | while read path
#inotifywait -mrq -e modify,create,delete $TOP | while read path x y
do
	dir=(`echo $path | sed 's:/: :g'`)
	repo=${dir[3]}
	if [ -d $TOP/$repo -a $last != $repo ]; then
		echo $repo
		#cp -av $TOP/$repo{,.build}
		#cd $TOP/${repo}.build
		#make
		#cd $TOP
		#rm -rf ${repo}.build
	fi
	last=$repo
done
