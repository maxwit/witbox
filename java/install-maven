#!/bin/sh

if [ $# != 1 ]; then
	echo "usage: $0 <maven path>!"
	exit 1
fi

MAVEN_HOME=$1

if [ ! -x $MAVEN_HOME/bin/mvn ]; then
	echo "invalid path: '$MAVEN_HOME'!"
	exit 1
fi

grep MAVEN_HOME $HOME/.bashrc
if [ $? = 0 ]; then
	echo "maven already installed!"
else
cat >> $HOME/.bashrc << EOF

export MAVEN_HOME=$MAVEN_HOME
export PATH=\$MAVEN_HOME/bin:\$PATH
EOF
	echo "maven successfully installed to $MAVEN_HOME"
fi
