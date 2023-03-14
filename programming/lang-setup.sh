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

temp=$(mktemp -d)

echo ">>>> C/C++"

os=$(uname -s)
case $os in
    Darwin)
		xcode-select --install
		brew install cmake pkg-config || exit 1
		;;
    Linux)
        cc_list="gcc g++ clang cmake pkg-config build-essential"
		which apt > /dev/null && sudo apt install -y $cc_list
		which dnf > /dev/null && sudo dnf install -y $cc_list
		;;
    *)
		echo "$os not supported! (skipped)"
esac

if [ ! pkg-config --exists fmt ]; then
    cd $temp
    while [ ! -d fmt ]
    do
        git clone https://github.com/fmtlib/fmt.git
    done

    mkdir -vp fmt/build && cd fmt/build
    cmake ..
    make -j4 && sudo make install
fi

echo ">>>> C#"

if ! dotnet --info | head -10; then
    curl -sfSL https://dot.net/v1/dotnet-install.sh | bash
    grep DOTNET_ROOT $profile || echo 'export DOTNET_ROOT=$HOME/.dotnet' >> $profile
    add_path '$HOME/.dotnet:$HOME/.dotnet/tools'
fi

echo ">>>> Dart"

flutter_path=$HOME/flutter
while [ ! -x $flutter_path/bin/dart ]
do
    rm -rf $flutter_path
    git clone https://github.com/flutter/flutter.git $flutter_path -b stable
done

add_path $flutter_path/bin

echo ">>>> Go"

mkdir -p $HOME/bin
add_path $HOME/bin

while [ ! -x $HOME/bin/gvm ]
do
    cd $temp && rm -rf gvm
    curl -L -O https://github.com/devnw/gvm/releases/download/latest/gvm && \
        install -v -m 755 gvm $HOME/bin/
done

# FIX gvm
if [ $(uname -m) == x86_64 ]; then
    $HOME/bin/gvm next
fi

echo ">>>> Java & Kotlin"

while [ ! -e ~/.sdkman/bin/sdkman-init.sh ]
do
    rm -rf ~/.sdkman
    curl -s https://get.sdkman.io | bash
done

source ~/.sdkman/bin/sdkman-init.sh
# FIXME
for pkg in java kotlin maven gradle
do
    for ((i=0;i<10;i++))
	do
        sdk install $pkg && break
    done
done

echo ">>>> JavaScript: deno"

for ((i=0;i<5;i++))
do
    curl -fsSL https://deno.land/install.sh | sh
    which deno && break
done

echo ">>>> JavaScript: node"

while [ ! ~/.nvm/nvm.sh ]
do
    cd $temp
    while [ ! -d nvm ]
    do
        git clone https://github.com/nvm-sh/nvm --depth 1
    done
    bash nvm/install.sh
done

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install --lts

echo ">>>> Rust"

if ! rustc --version; then
    for ((i=0;i<10;i++))
    do
        curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh
        [ $? -eq 0 ] && break
    done
fi

# echo ">>>> Swift"

# if ! docker --version; then
#     case $(uname -s) in
#     Darwin)
#         brew install docker
#         ;;
#     Linux)
#         curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
#         sudo usermod -aG docker $USER
#         newgrp docker
#         ;;
#     esac
# fi

# for ((i=0;i<10;i++))
# do
#     docker pull swift && break
# done

# clean up
rm -rf $temp

echo "All Done!"
