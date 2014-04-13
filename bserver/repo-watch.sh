#!/bin/bash

DOC_ROOT=$HOME/document

tab=`mktemp`

#for doc in `ls $DOC_ROOT`
for doc in testing
do
	if [ -d $DOC_ROOT/$doc ]; then
		inode="/home/git/repositories/$doc.git/refs/heads"
		if [ -e $inode ]; then
			echo $inode IN_CLOSE_WRITE /home/conke/project/witbox/bserver/repo-build.sh \$@ >> $tab
		else
			echo "$inode: No such file"
		fi
	fi
done

incrontab $tab
incrontab -d
