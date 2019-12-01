#!/usr/bin/env bash

if [ $UID -ne 0 ]; then
    echo "pls run as root!"
    exit 1
fi

if [ -e /etc/redhat-release ]; then
    eval `cat /etc/os-release | grep VERSION_ID`

    cd /etc/yum.repos.d/

    if [ ! -z "$VERSION_ID" -a "$VERSION_ID" -lt 8 ]; then
        if [ ! -e repo-back.tar ]; then
            tar cvf repo-back.tar *.repo
        fi
        yum remove -y epel-release
        rm -vf *.repo

        wget http://mirrors.aliyun.com/repo/Centos-${VERSION_ID}.repo
        wget http://mirrors.aliyun.com/repo/epel-${VERSION_ID}.repo
    else # FIXME
        sed -i -e 's/mirrorlist=/#mirrorlist=/g' \
            -e 's/#baseurl=/baseurl=/g' \
            -e 's#http://mirror.centos.org#https://mirrors.aliyun.com#g' *.repo
    fi

    yum clean all
    yum repolist enabled
else
    codename=`lsb_release -sc`
    tee /etc/apt/sources.list << EOF
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
    apt update -y
fi

which docker > /dev/null || curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

usermod -aG docker $USER

if [ ! -e /etc/docker/daemon.json ]; then
    mkdir -p /etc/docker
    tee /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://registry.docker-cn.com"]
}
EOF
    systemctl restart docker
fi
