#!/usr/bin/env bash

if [ $UID -eq 0 ]; then
    echo "do NOT run as root!"
    exit 1
fi

os=`uname -s`

case $os in
Linux)
    eval `egrep -w '(ID|VERSION_ID)' /etc/os-release`

    case $ID in
    centos)
        cd /etc/yum.repos.d/

        if [ ! -e repo-back.tar ]; then
            sudo tar cvf repo-back.tar *.repo
        fi
        sudo yum remove -y epel-release
        sudo rm -vf *.repo

        sudo wget http://mirrors.aliyun.com/repo/Centos-${VERSION_ID}.repo || exit 1
        sudo wget http://mirrors.aliyun.com/repo/epel-${VERSION_ID}.repo || sudo yum install -y epel-release # walkaround for centos8
        sudo yum clean all
        sudo yum repolist enabled
        sudo yum update -y
        sudo yum autoremove -y
        ;;

    ubuntu)
        codename=`lsb_release -sc`
        sudo tee /etc/apt/sources.list << EOF
deb http://mirrors.aliyun.com/ubuntu/ ${codename} main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ ${codename}-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ ${codename}-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ ${codename}-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ ${codename}-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${codename} main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${codename}-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${codename}-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${codename}-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${codename}-backports main restricted universe multiverse
EOF
        sudo apt update -y || exit 1
        sudo apt upgrade -y
        sudo apt autoremove -y
        ;;
    esac

    ;;

Darwin)
    which brew > /dev/null || {
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit 1
    }

    git -C "$(brew --repo)" config --list | grep tsinghua > /dev/null || {
        git -C "$(brew --repo)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
        git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
        git -C "$(brew --repo homebrew/cask)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git
        brew update
    }

    ;;

*)
    echo "'$os' not supported yet!"
    ;;
esac

echo "$USER ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER