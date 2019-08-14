mkdir -p ~/.pip
cat > ~/.pip/pip.conf << EOF
[global]
trusted-host = mirrors.aliyun.com
index-url = https://mirrors.aliyun.com/pypi/simple
EOF

if [ -e /etc/redhat-release ]; then
	sudo yum install -y sudo yum-utils

	sudo yum remove -y epel-release
	if [ ! -e /etc/sudo yum.repos.d/repo-back.tar ]; then
		tar cvf /etc/sudo yum.repos.d/repo-back.tar /etc/sudo yum.repos.d/*.repo
	fi
	rm -vf /etc/sudo yum.repos.d/*.repo

	sudo yum-config-manager --add-repo \
		http://mirrors.aliyun.com/repo/Centos-7.repo

	sudo yum-config-manager --add-repo \
		http://mirrors.aliyun.com/repo/epel-7.repo

	# sudo yum-config-manager --add-repo \
	#     https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

	sudo yum clean all
	sudo yum repolist enabled
else
	codename=`lsb_release -sc`
	tmp=`mktemp`
	cat > $tmp << EOF
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
	sudo cp $tmp /etc/apt/sources.list
	rm $tmp
	sudo apt update -y
fi

curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://2r2lwgn9.mirror.aliyuncs.com"]
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
