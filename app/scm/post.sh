#!/bin/sh
#

# fixme
FULL_NAME=`grep $USER /etc/passwd | awk -F '[:,]' '{print $5}'`
USER_GROUP=`groups ${USER} | awk '{print $3}'`

if [ -z "${USER_EMAIL}" ]; then
	if [ "${USER_GROUP}" = "mwmgr" ]; then
		USER_EMAIL="${USER}@maxwit.com"
	else # elif [ "${USER_GROUP}" = "mwsse" ]; then
		USER_EMAIL=`echo ${FULL_NAME} | tr 'A-Z' 'a-z' | sed 's/ /./g'`
		USER_EMAIL="${USER_EMAIL}@maxwit.com"
	fi
fi

USER_PASS=MW111`echo ${FULL_NAME} | sed 's/\s//g'`

############## configure E-mail client ############
echo
echo "######################################"
printf "#      %15s's             #\n"  $USER
echo "#         Account Information        #"
echo "######################################"
#echo "User Name = \"$USER\""
echo "Full Name = \"$FULL_NAME\""
echo "User Mail = \"$USER_EMAIL\""
echo

#for rc in msmtprc muttrc
for rc in msmtprc
do
	if [ -e ~/.$rc ]; then
		echo "Skipping ${HOME}/.$rc"
	else
		sed -e "s/student_at_maxwit/${USER_EMAIL}/" -e "s/student_init_password/${USER_PASS}/" \
			$rc > ~/.$rc

		chmod 600 ~/.$rc
	fi
done

#mkdir -p ~/Mail/
#touch ~/Mail/Inbox ~/Mail/Sent ~/Mail/Postponed

############# configure git ############
echo "---- GIT Configuration ---"
git config --list | grep ^color.ui || \
	git config --global color.ui auto

git config --list | grep ^user.name || \
	git config --global user.name "${FULL_NAME}"

git config --list | grep ^user.email || \
	git config --global user.email ${USER_EMAIL}

git config --list | grep ^sendemail.smtpserver || \
	git config --global sendemail.smtpserver /usr/bin/msmtp
