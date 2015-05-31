#!/bin/sh

if [ $# != 1 ]; then
	echo "usage: $0 <JDK PATH>!"
	exit 1
fi

JAVA_HOME=$1

if [ ! -x $JAVA_HOME/bin/javac ]; then
	echo "invalid path: '$JAVA_HOME'!"
	exit 1
fi

grep JAVA_HOME $HOME/.bashrc
if [ $? = 0 ]; then
	echo "JDK already installed!"
else
cat >> $HOME/.bashrc << EOF

export JAVA_HOME=$JAVA_HOME
export CLASS_PATH=.:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
	echo "JDK successfully installed to $JAVA_HOME"
fi
