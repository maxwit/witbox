#!/bin/sh

if [ ! -d $dir ]
then
	mkdir -p  $HOME/project
fi

cd $HOME/project

projectlist=(android/witmail book/books book/java book/dba book/jee dba/deploy hadoop/witdh iot/toolchain iot/mini-lablin iot/qemu-omap iot/fbv iot/withttp jee/mybatis-demo jee/app-demo jee/witweb-sh jee/task jee/withttp jee/deploy jee/jsp-demo jee/witweb pub/book pub/jse pub/demo sys/withost sys/witbox web/e-lib)

for item in ${projectlist[@]};
do
	cd $HOME/project/$item
	branchlist=(`git branch -r`)

	for branch in ${branchlist[@]}
	do
		if echo $branch | egrep -q HEAD
		then
			continue
		fi
		realbranch=${branch#origin/}
		git checkout $realbranch
		git push -u git@git.debug.live:$item $realbranch
	done

	git remote set-url origin git@git.debug.live:$item
done 
