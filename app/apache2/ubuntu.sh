#!/bin/sh

sudo cp python.conf /etc/apache2/mods-available/ && sudo ln -s ../mods-available/python.conf /etc/apache2/mods-enabled/python.conf
sudo sed -i '/<Directory \/var\/www\/>/a\\t\tAddHandler mod_python .py\n\t\tPythonHandler index\n\t\tPythonDebug On' /etc/apache2/sites-enabled/000-default
sudo cp index.py /var/www/
