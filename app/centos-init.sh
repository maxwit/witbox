#/bin/sh

cd /tmp
wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
sudo rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
sudo rpm -K rpmforge-release-0.5.2-2.el6.rf.*.rpm
sudo rpm -i rpmforge-release-0.5.2-2.el6.rf.*.rpm

cp /etc/yum.repos.d/CentOS-Base.repo .
cat google >> CentOS-Base.repo
sudo mv CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
