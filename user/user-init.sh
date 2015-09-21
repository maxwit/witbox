#!/bin/bash

cat > ~/.vimrc << EOF
set nu
set ts=4
set hlsearch
let c_space_errors=1
let java_space_errors=1
EOF

cat > ~/.emacs << EOF
(global-linum-mode t)
EOF

#if [ ! -e ~/.ssh/id_rsa ]; then
#	scp -r build.maxwit.com:~/.ssh ~/
#fi

fullname=$(awk -F : -v user=$USER '$1==user {print $5}' /etc/passwd)
fullname=${fullname/,*}
account=${fullname// /.}
account=$(echo $account | tr A-Z a-z)

git config --global user.name "$fullname"
git config --global user.email $account@maxwit.com
git config --global color.ui auto
git config --global push.default simple
git config --global sendemail.smtpserver /usr/bin/msmtp
git config --global merge.ours.driver true
git config --list

echo
