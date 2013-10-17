#!/bin/sh

sudo cp python.conf /etc/apache2/mods-available/ && \
sudo ln -s ../mods-available/python.conf /etc/apache2/mods-enabled/python.conf
