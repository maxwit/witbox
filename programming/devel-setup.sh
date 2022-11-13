#!/usr/bin/env bash

case $SHELL in
*zsh)
    profile=$HOME/.zshrc
    ;;
*bash)
    profile=$HOME/.bashrc
    ;;
*)
    exit 1
esac

add_path() {
    grep "PATH.*$1" $profile || echo "export PATH=\$PATH:$1" >> $profile
}

mkdir -p ~/bin

add_path $HOME/bin

# Dart
cd
while [ ! -d flutter/bin ]
do
    rm -rf flutter
    git clone https://github.com/flutter/flutter.git -b stable
done

add_path `pwd`/flutter/bin

# GO
while [ ! -e $HOME/bin/gvm ]
do
    curl -L https://github.com/devnw/gvm/releases/download/latest/gvm > $HOME/bin/gvm
done

chmod +x $HOME/bin/gvm

# FIXME
$HOME/bin/gvm 1.19.3

# Java & Kotlin
while [ ! -e ~/.sdkman/bin/sdkman-init.sh ]
do
    rm -rf ~/.sdkman
    curl -s "https://get.sdkman.io" | bash
done

source ~/.sdkman/bin/sdkman-init.sh

# FIXME
for pkg in "java 11.0.16-amzn" kotlin maven gradle
do
    while true; do sdk install $pkg && break; done
done

# JavaScript/TypeScript
# Deno
curl -fsSL https://deno.land/install.sh | sh

# NVM
while [ ! -d nvm ]
do
    git clone https://github.com/nvm-sh/nvm -depth 1
done

bash nvm/install.sh

$SHELL -l

nvm install --lts
