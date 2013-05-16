#!/bin/sh

#sudo chkconfig nfs on

sudo sed -i '$a\/maxwit/pub 192.168.0.*(rw,async) *(ro)' /etc/exports
sudo sed -i '$a\MOUNTD_PORT="4002"\nSTATD_PORT="4003"\nLOCKD_TCPPORT="4004"\nLOCKD_UDPPORT="4004"' /etc/sysconfig/nfs
sudo sed -i '/\:OUTPUT ACCEPT \[0\:0\]/a\-A INPUT -p udp --dport 2049 -j ACCEPT\n-A INPUT -p tcp --dport 2049 -j ACCEPT\n-A INPUT -p udp --dport 111 -j ACCEPT\n-A INPUT -p tcp --dport 111 -j ACCEPT\n-A INPUT -m state --state NEW -m tcp -p tcp --dport 4002:4004 -j ACCEPT\n-A INPUT -m state --state NEW -m udp -p udp --dport 4002:4004 -j ACCEPT' /etc/sysconfig/iptables
sudo /etc/init.d/iptables restart
sudo /etc/init.d/rpcbind start
sudo /etc/rc.d/init.d/nfs start

