#!/usr/bin/env bash

if [ ! -d $dir ]
then
	mkdir -p  $HOME/project
fi

cd $HOME/project

projectlist=(android/witmail book/books book/java book/dba book/jee dba/deploy hadoop/witdh iot/toolchain iot/mini-lablin iot/qemu-omap iot/fbv iot/withttp jee/mybatis-demo jee/app-demo jee/witweb-sh jee/task jee/withttp jee/deploy jee/jsp-demo pub/book pub/jse pub/demo web/e-lib)

for item in ${projectlist[@]};
do
	cd $HOME/project/$item
	branchlist=`git branch -r | sed '/HEAD/d'`

	for branch in $branchlist
	do
		realbranch=${branch#origin/}
		git checkout $realbranch
		git push -u git@git.debug.live:$item $realbranch
	done

	git remote set-url origin git@git.debug.live:$item
done 
