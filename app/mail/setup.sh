#!/bin/sh

FULL_NAME=$1
USER_EMAIL=$2

USER_PASS="maxwit"

############## configure E-mail client ############
echo
echo "######################################"
echo "#         Account Information        #"
echo "######################################"
echo "Full Name = \"$FULL_NAME\""
echo "User Mail = \"$USER_EMAIL\""
echo

for rc in msmtprc muttrc
do
	if [ -e ~/.$rc ]; then
		echo "Skipping ${HOME}/.$rc"
	else
		sed -e "s/user_at_maxwit/${USER_EMAIL}/" -e "s/user_init_password/${USER_PASS}/" \
			$rc > ~/.$rc

		chmod 600 ~/.$rc
	fi
done

mkdir -p ~/Mail/
touch ~/Mail/Inbox ~/Mail/Sent ~/Mail/Postponed
