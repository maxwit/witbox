#!/usr/bin/python


import os,sys,re
import platform
from optparse import OptionParser
from xml.etree import ElementTree

def check(user):
	fp = open("/home/%s/.msmtprc" % user, 'r')
	for line in fp:
		if line.startswith("account"):
			account = line.split(' ')[1]
			if account == "default:":
				account = line.split(' ')[2]

	print "checking email setting ..."
	return

if __name__ == "__main__":
	current_user = os.getenv("USER")
	if current_user == "root":
		print "cannot run as root!"
		exit()

	check(current_user)
