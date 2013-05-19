#/bin/sh

sudo chkconfig smb on
sudo sed -i '/\:OUTPUT ACCEPT \[0\:0\]/a\-A INPUT -p udp --dport 137 -j ACCEPT\n-A INPUT -p udp --dport 138 -j ACCEPT\n-A INPUT -m state --state NEW -m tcp -p tcp --dport 139 -j ACCEPT\n-A INPUT -m state --state NEW -m tcp -p tcp --dport 445 -j ACCEPT' /etc/sysconfig/iptables
sudo /etc/init.d/iptables restart

sudo sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

cp /etc/samba/smb.conf .
cat samba >> smb.conf
sudo mv smb.conf /etc/samba/smb.conf
sudo /etc/init.d/smb start
