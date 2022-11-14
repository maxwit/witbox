#!/usr/bin/env bash

case $SHELL in
*zsh)
    profile=$HOME/.zshrc
    ;;
*bash|*dash)
    profile=$HOME/.bashrc
    ;;
*)
    echo "$SHELL not supported!"
    exit 1
esac

add_path() {
    grep "PATH.*$1" $profile || echo -e "\nexport PATH=\$PATH:$1" >> $profile
}


echo ">>>> C/C++"
os=$(uname -s)
case $os in
    Darwin)
	xcode-select --install
	brew install fmt pkg-config || exit 1
	;;
    Linux)
	which apt > /dev/null && sudo apt install -y clang libfmt-dev pkg-config
	which dnf > /dev/null && sudo dnf install -y clang fmt-devel pkg-config
	;;
    *)
	echo "$os not supported!"
	exit 1
esac

echo ">>>> Dart"
cd
while [ ! -d flutter/bin ]
do
    rm -rf flutter
    git clone https://github.com/flutter/flutter.git -b stable
done

add_path `pwd`/flutter/bin

echo ">>>> Go"
mkdir -p $HOME/bin
add_path $HOME/bin

while [ ! -x $HOME/bin/gvm ]
do
    curl -L -O https://github.com/devnw/gvm/releases/download/latest/gvm && install -v -m 755 gvm $HOME/bin/
done

#$HOME/bin/gvm 1.19.3

echo ">>>> Java & Kotlin"
while [ ! -e ~/.sdkman/bin/sdkman-init.sh ]
do
    rm -rf ~/.sdkman
    curl -s "https://get.sdkman.io" | bash
done

source ~/.sdkman/bin/sdkman-init.sh

# FIXME
for pkg in java kotlin maven gradle
do
    while true; do sdk install $pkg && break; done
done

echo ">>>> JavaScript: Deno"
curl -fsSL https://deno.land/install.sh | sh

echo ">>>> JavaScript: NVM"
while [ ! -d nvm ]
do
    git clone https://github.com/nvm-sh/nvm --depth 1
done

bash nvm/install.sh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install --lts

echo ">>>> Rust"
which rustc || curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh

echo "All Done!"
