#!/usr/bin/python

import os

#defaults
#
#account qq
#host smtp.qq.com
#user 1450028115@qq.com
#from 1450028115@qq.com
#auth login
#
#account default: qq

def do_setup(distrib, version, config):
	user = config['user.name']
	mail = config['user.mail']
	domain = mail.split('@')[1]
	host = 'smtp.' + domain

	print 'setup msmtp ...'

	fd = open(os.getenv('HOME') + '/.msmtprc', 'w+')
	fd.write('defaults\n\n')
	fd.write('account %s\n' % domain)
	fd.write('host %s\n' % host)
	fd.write('user %s\n' % mail)
	#fd.write('from "%s" <%s>\n' % (user, mail))
	fd.write('from %s\n' % mail)
	fd.write('auth login\n\n')
	fd.write('account default: %s' % domain)
	fd.close()

msmtp_config = {}

def do_report(key, rep_fn, config_list):
	print 'Getting report information...'
	rep_fd = open(rep_fn, "aw")
	if key == 'install':
		rep_fd.write('Installation setting report:\n\n')
		rep_fd.flush()
		os.system("dpkg -l vim vim-gnome gcc g++>> %s" % rep_fn)
		rep_fd.write('\n')
	elif key == 'mail':
		rep_fd.write('Mail setting report:\n\n')
		rep_fd.flush()
		os.system("dpkg -l msmtp >> %s" % rep_fn)
		rep_fd.write('\n')
		user = os.getenv('USER')
		fd = open('/home/%s/.msmtprc' % user)
		for line in fd:
			if line != '\n' and line.strip().startswith('#') == False:
				key_value = line.strip().split(' ', 1)
				if len(key_value) == 2:
					msmtp_config[key_value[0].strip()] = key_value[1].strip()
		fd.close()

		if msmtp_config.has_key('host') != True:
			rep_fd.write('Host is not configured in file msmtprc!\n')
		elif msmtp_config['host'] != 'smtp.qq.com':
			rep_fd.write('Expected host is smtp.qq.com, yours is %s\n' % msmtp_config['host'])
		else:
			rep_fd.write('Host is configured correctly!\n')

		if msmtp_config.has_key('user') != True:
			rep_fd.write('User is not configured in file msmtprc\n')
		elif msmtp_config['user'] != config_list['user.mail']:
			rep_fd.write('Expected user is %s, yours is %s\n' % (config_list['user.mail'], msmtp_config['user']))
		else:
			rep_fd.write('User is configured correctly!\n')

		if msmtp_config.has_key('from') != True:
			rep_fd.write('From is not configured in file msmtprc\n')
		elif msmtp_config['from'] != config_list['user.mail']:
			rep_fd.write('Expected from is %s, yours is %s\n' % (config_list['user.mail'], msmtp_config['from']))
		else:
			rep_fd.write('From is configured correctly!\n')
