#!/usr/bin/env bash

if [ $UID -eq 0 ]; then
    echo "do NOT run as root!"
    exit 1
fi

mkdir -p ~/.pip
cat > ~/.pip/pip.conf << EOF
[global]
trusted-host = mirrors.aliyun.com
index-url = https://mirrors.aliyun.com/pypi/simple
EOF