#!/bin/sh

echo "---- GIT Configuration ---"
git config --list | grep ^color.ui || \
	git config --global color.ui auto

git config --list | grep ^user.name || \
	git config --global user.name "$1"

git config --list | grep ^user.email || \
	git config --global user.email $2

git config --list | grep ^sendemail.smtpserver || \
	git config --global sendemail.smtpserver /usr/bin/msmtp
