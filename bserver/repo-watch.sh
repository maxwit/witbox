#!/bin/bash

DOC_ROOT=$HOME/document

tab=`mktemp`

for doc in `ls $DOC_ROOT`
do
	inode="/home/git/repositories/document/$doc.git/refs/heads"
	if [ -e $inode ]; then
		echo $inode IN_CLOSE_WRITE /home/conke/project/witbox/bserver/repo-build.sh \$@ >> $tab
	else
		echo "$inode: No such file"
	fi
done

incrontab $tab
incrontab -d
