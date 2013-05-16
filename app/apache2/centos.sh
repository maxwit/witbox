#!/bin/sh

cd /tmp
wget http://archive.apache.org/dist/httpd/modpython/mod_python-3.3.1.tgz
gunzip mod_python-3.3.1.tgz 
tar xvf mod_python-3.3.1.tar 
cd mod_python-3.3.1
sed -i 's/b == APR_BRIGADE_SENTINEL(b)/b == APR_BRIGADE_SENTINEL(bb)/g' src/connobject.c
./configure --with-apxs=`which apxs` --with-python=`which python`
make
make install
sudo make install

sudo sed -i '$a\LoadModule python_module modules/mod_python.so' /etc/httpd/conf/httpd.conf
sudo sed -i '/<Directory "\/var\/www\/html">/a\\tAddHandler mod_python .py\n\tPythonHandler index\n\tPythonDebug On' /etc/httpd/conf/httpd.conf
sudo cp index.py /var/www/

sudo chkconfig httpd on
sudo sed -i '/\:OUTPUT ACCEPT \[0\:0\]/a\' /etc/sysconfig/iptables 
