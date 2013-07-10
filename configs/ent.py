#!/usr/bin/python

import os

def do_setup(distrib, version, config):
	user = config['user.name']
	mail = config['user.mail']
	domain = mail.split('@')[1]
	# host = 'smtp.' + domain

	print 'setup msmtp ...'
	fd = open(os.getenv('HOME') + '/.msmtprc', 'w+')
#defaults
#
#account qq
#host smtp.qq.com
#user 1450028115@qq.com
#from 1450028115@qq.com
#password ???
#auth login
#
#account default: qq
	fd.write('defaults\n\n')
	fd.write('account %s\n' % domain)
	fd.write('host smtp.%s\n' % domain)
	fd.write('user %s\n' % mail)
	#fd.write('from "%s" <%s>\n' % (user, mail))
	fd.write('from %s\n' % mail)
	fd.write('password ???\n')
	fd.write('auth login\n\n')
	fd.write('account default: %s' % domain)
	fd.close()

	print 'setup mutt ...'
	fd = open(os.getenv('HOME') + '/.muttrc', 'w+')
## pop3
#set pop_user=conke.hu@maxwit.com
#set pop_pass="printfMW13"
#set pop_host=pops://pop.maxwit.com
#set pop_last=yes
#set pop_delete=no
#set check_new=yes
#set timeout=1800
	fd.write("# pop3 setting\n")
	fd.write("set pop_user = %s\n" % mail)
	fd.write("set pop_pass = ???\n")
	fd.write("set pop_host = pops://pop.%s\n" % domain)
	fd.write("set pop_last = yes\n")
	fd.write("set pop_delete = no\n")
	fd.write("set check_new = yes\n")
	fd.write("set timeout = 1800\n")
	fd.write("\n")

## msmtp setting
#set sendmail="/usr/bin/msmtp"
## set use_from=yes
## set from=
## set envelope_from=yes
	fd.write("# msmtp setting\n")
	fd.write("set sendmail = /usr/bin/msmtp\n")
	fd.write("# set use_from = yes\n")
	fd.write("# set from = %s\n", )
	fd.write("# set envelope_from = yes\n")
	fd.write("\n")

#my_hdr From: 
	fd.write("my_hdr From: %s\n" % mail)
	fd.write("\n")

	fd.close()

msmtp_config = {}

def do_report(key, rep_fn, config_list):
	print 'Getting report information...'
	rep_fd = open(rep_fn, "aw")
	if key == 'install':
		rep_fd.write('Installation setting report:\n\n')
		rep_fd.flush()
		os.system("dpkg -l vim vim-gnome gcc g++ >> %s" % rep_fn)
		rep_fd.write('\n')
	elif key == 'mail':
		rep_fd.write('Mail setting report:\n\n')
		rep_fd.flush()
		os.system("dpkg -l msmtp mutt >> %s" % rep_fn)
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
