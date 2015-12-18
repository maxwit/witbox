#!/bin/sh

if [ ! -d $dir ]
then
	mkdir -p $HOME/project
fi

cd $HOME/project

projectlist=(android/witmail book/books book/java book/dba book/jee dba/deploy hadoop/witdh iot/toolchain iot/mini-lablin iot/qemu-omap iot/fbv iot/withttp jee/mybatis-demo jee/app-demo jee/witweb-sh jee/task jee/withttp jee/deploy jee/jsp-demo jee/witweb p2p/p2p-rwx pub/book pub/jse pub/demo sys/withost sys/witbox sys/task web/e-lib)

for item in ${projectlist[@]};
do
	project=$item
	git clone git@192.168.3.5:$project $project
done 
