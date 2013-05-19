#!/bin/sh
#

# fixme
FULL_NAME=`grep $USER /etc/passwd | awk -F '[:,]' '{print $5}'`
USER_GROUP=`groups ${USER} | awk '{print $3}'`

if [ -z "${USER_EMAIL}" ]; then
	USER_EMAIL=`echo ${FULL_NAME} | tr 'A-Z' 'a-z' | sed 's/ /./g'`
	USER_EMAIL="${USER_EMAIL}@maxwit.com"
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

for rc in msmtprc muttrc
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
