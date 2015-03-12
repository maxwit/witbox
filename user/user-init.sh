#!/bin/bash

cat > ~/.vimrc << EOF
set nu
set ts=4
set hlsearch
let c_space_errors=1
let java_space_errors=1
EOF

if [ ! -e ~/.ssh/id_rsa ]; then
	scp -r file.maxwit.org:~/.ssh ~/
fi

git config --global user.name "Conke Hu"
git config --global user.email conke.hu@maxwit.com
git config --global color.ui auto
git config --global push.default simple
git config --list

echo
