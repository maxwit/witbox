#!/usr/bin/env bash

TOP=$PWD

for dir in `ls`
do
	if [ -d $dir ]; then
		for repo in `ls $dir`
		do
			cd $dir/$repo

			echo "$dir/$repo:"
			for b in `git branch -r | sed '/HEAD/d'`
			do
				branch=`basename $b`
				if [ -e $TOP/$dir-$repo-$branch ]; then
					continue
				fi

				git checkout $branch || exit 1
				git push -u origin $branch
				if [ $? == 0 ]; then
					touch $TOP/$dir-$repo-$branch
				else
					url=`git config remote.origin.url`
					echo "fail to push $repo/$branch -> $url"
					exit 1
				fi
				echo
			done
			cd -
			echo
		done	
	fi
done
