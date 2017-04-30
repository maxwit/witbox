#!/usr/bin/env bash

TOP_DIR=$PWD
TMP_DIR=`mktemp -d`
echo $TMP_DIR

qqs=`awk -F, '{print $1}' names`
cc=
for qq in $qqs
do
	cc+=$qq@qq.com,
done
cc=`echo $cc | sed -e s/,$//`
echo $cc

for qq_name in `cat names`
do
	echo "to $qq_name ..."
	qq=`echo $qq_name | awk -F, '{print $1}'`
	name=`echo $qq_name | awk -F, '{print $2}'`
	cd $TMP_DIR
	ptn="powertool-alpha-$qq"

	cp -r /maxwit/project/powertool $ptn
	cd $ptn
	rm -rf .git
	./powertool -c entrance
	sed -i "s/user.name\s*=.*/user.name = $name/" .config
	sed -i "s/user.mail\s*=.*/user.mail = $qq@qq.com/" .config
	sed -i "s/mail.cc\s*=.*/mail.cc = $cc/" .config
	cd ..
	tar cjf $ptn.tar.bz2 $ptn

	mutt -s powertool $qq@qq.com -a $ptn.tar.bz2 < $TOP_DIR/msg

	echo
done
