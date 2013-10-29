#!/bin/sh

DOCUMENT_PATH="/maxwit/document"
PROJECT=`echo $1|awk -F '/' '{print $6}'`
PROJECT_NAME=`echo $PROJECT|awk -F '.' '{print $1}'`
DOCUMENT_PUB="/maxwit/share"

cd $DOCUMENT_PATH/$PROJECT_NAME
su texbuild -c "git pull"
su texbuild -c "make"
cp *.pdf $DOCUMENT_PUB/$PROJECT_NAME
