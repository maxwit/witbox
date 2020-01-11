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

        sudo wget http://mirrors.aliyun.com/repo/Centos-${VERSION_ID}.repo
        sudo wget http://mirrors.aliyun.com/repo/epel-${VERSION_ID}.repo
        sudo yum clean all
        sudo yum repolist enabled
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
        sudo apt update -y
        ;;
    esac

        which docker > /dev/null || curl -fsSL https://get.docker.com | sudo bash -s docker --mirror Aliyun
        sudo usermod -aG docker $USER
        if [ ! -e /etc/docker/daemon.json ]; then
            sudo mkdir -p /etc/docker
            sudo tee /etc/docker/daemon.json << EOF
{
    "registry-mirrors": ["https://registry.docker-cn.com"]
}
EOF
        sudo systemctl restart docker
    fi

    ;;

Darwin)
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    git -C "$(brew --repo)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
    git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
    git -C "$(brew --repo homebrew/cask)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git
    brew update

    ;;
esac

# now go on with user mode:

mkdir -p ~/.pip
cat > ~/.pip/pip.conf << EOF
[global]
trusted-host = mirrors.aliyun.com
index-url = https://mirrors.aliyun.com/pypi/simple
EOF
