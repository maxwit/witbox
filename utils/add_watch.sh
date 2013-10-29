#!/bin/sh

TOP_PATH="/maxwit/project/powertool/utils"
GIT_HOME="/home/git"
DOCUMENT_PATH="/maxwit/document"
PROJECT_NAME=`echo $1|awk -F '.' '{print $1}'`

su texbuild -c "git clone git@127.0.0.1:document/$PROJECT_NAME $DOCUMENT_PATH/$PROJECT_NAME"

echo "$GIT_HOME/repositories/document/$1/refs/heads IN_CLOSE_WRITE sh $TOP_PATH/document_build.sh \$@" >> $TOP_PATH/root
cp $TOP_PATH/root /var/spool/incron/
service incrond restart
