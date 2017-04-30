#!/usr/bin/env bash

KEY_FILE="/tmp/${USER}.pub"

cp ~/.ssh/id_rsa.pub ${KEY_FILE}
echo "This is my ssh key." | mutt devel@maxwit.com -s "[SSH] ${USER}'s key" -a ${KEY_FILE} 

rm ${KEY_FILE}
