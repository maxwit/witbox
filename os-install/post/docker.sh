#!/usr/bin/env bash

if [ $UID -eq 0 ]; then
    echo "do NOT run as root!"
    exit 1
fi

os=`uname -s`
if [ $os = macOS ]; then
    while true; do
        brew cask install docker && break
    done
    exit 0
fi

which docker > /dev/null || {
    curl -fsSL https://get.docker.com | sudo bash -s docker --mirror Aliyun
    sudo usermod -aG docker $USER
    sudo systemctl enable --now docker
}

if [ ! -e /etc/docker/daemon.json ]; then
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json << EOF
{
    "registry-mirrors": ["https://registry.docker-cn.com"]
}
EOF
    sudo systemctl restart docker
fi
