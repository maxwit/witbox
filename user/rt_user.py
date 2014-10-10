#!/usr/bin/python

import os, re, sys
import platform
from xml.etree import ElementTree
from lib import base

class rt_user(object):
	def __init__(self):
		self.login = os.getenv('USER')
		self.home = os.getenv('HOME')
		self.fname = base.get_full_name(self.login)
		# to be removed!
		mail_user = self.fname.lower().replace(' ', '.')
		# FIXME: detect the Windows domain
		self.email = mail_user + '@maxwit.com'
		if self.fname == mail_user:
			print 'Please make sure your mail account (%s) is correct!' % self.email

	def config(self, conf):
		if not os.path.exists(self.home + '/.ssh/id_rsa.pub'):
			os.system("echo | ssh-keygen -N ''")

			fd_config = open(self.home + '/.ssh/config', 'w')
			fd_config.write("StrictHostKeyChecking no")
			fd_config.close()
			os.chmod(self.home + '/.ssh/config', 0600)

		if not conf.has_key('sys.apps'):
			return

		for app in conf['sys.apps'].split():
			if not os.path.exists('user/%s.py' % app):
				continue

			print 'Configuring %s:' % app

			try:
				mod = __import__('user.%s' % app, fromlist = ['config'])
				rc = mod.config(self, conf)
			except Exception, e:
				print "%r\n" % e
				continue

			for fn in rc:
				print fn

			print
