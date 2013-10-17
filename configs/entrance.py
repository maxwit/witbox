#!/usr/bin/python

import os
import platform

def do_setup(distrib, version, config):
	user = config['user.name']
	mail = config['user.mail']
	domain = mail.split('@')[1]
	# host = 'smtp.' + domain

	print 'setup msmtp ...'
	fd_rept = open(os.getenv('HOME') + '/.msmtprc', 'w+')
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
	fd_rept.write('defaults\n\n')
	fd_rept.write('account %s\n' % domain)
	fd_rept.write('host smtp.%s\n' % domain)
	fd_rept.write('user %s\n' % mail)
	#fd_rept.write('from "%s" <%s>\n' % (user, mail))
	fd_rept.write('from %s\n' % mail)
	fd_rept.write('password ???\n')
	fd_rept.write('auth login\n\n')
	fd_rept.write('account default: %s' % domain)
	fd_rept.close()

	os.chmod(os.getenv('HOME') + '/.msmtprc', 0600)

	print 'setup mutt ...'
	fd_rept = open(os.getenv('HOME') + '/.muttrc', 'w+')
## pop3
#set pop_user=conke.hu@maxwit.com
#set pop_pass="???"
#set pop_host=pops://pop.maxwit.com
#set pop_last=yes
#set pop_delete=no
#set check_new=yes
#set timeout=1800
	fd_rept.write("# pop3 setting\n")
	fd_rept.write("set pop_user = %s\n" % mail)
	fd_rept.write("set pop_pass = ???\n")
	fd_rept.write("set pop_host = pops://pop.%s\n" % domain)
	fd_rept.write("set pop_last = yes\n")
	fd_rept.write("set pop_delete = no\n")
	fd_rept.write("set check_new = yes\n")
	fd_rept.write("set timeout = 1800\n")
	fd_rept.write("\n")

## msmtp setting
#set sendmail="/usr/bin/msmtp"
## set use_from=yes
## set from=
## set envelope_from=yes
	fd_rept.write("# msmtp setting\n")
	fd_rept.write("set sendmail = /usr/bin/msmtp\n")
	fd_rept.write("# set use_from = yes\n")
	fd_rept.write("# set from = %s\n", )
	fd_rept.write("# set envelope_from = yes\n")
	fd_rept.write("\n")

#my_hdr From: 
	fd_rept.write("my_hdr From: %s\n" % mail)
	fd_rept.write("\n")

	fd_rept.close()

	os.chmod(os.getenv('HOME') + '/.muttrc', 0600)

def check_install(fd_rept, conf_list):
	fd_rept.write('########################################\n')
	fd_rept.write('\tPartition and File System\n')
	fd_rept.write('########################################\n')

	fd_chk = open('/proc/mounts')
	for line in fd_chk:
		mount = line.split(' ')
		fd_rept.write('%s %s %s\n' % (mount[0], mount[1], mount[2]))
	fd_rept.write('\n')

# def check_apps(fd_rept, conf_list):
	fd_rept.write('########################################\n')
	fd_rept.write('\tApplications Installation\n')
	fd_rept.write('########################################\n')

	for line in os.popen("dpkg -l vim gcc g++ msmtp mutt"):
		fd_rept.write(line)
	fd_rept.write('\n')

def do_report(task, mail_info, config_list):
	fd_rept = mail_info[0]
	if task == 'help' or task != 'help' and task != 'install' and task != 'command':
		print 'usage:\n' \
			'./powertool -r install: Report System Installation\n' \
			'./powertool -r command: Report Linux Commands Practice\n'
		fd_rept.close()
		return False

	print 'checking %s ...' % task

	if task == 'install':
		check_install(fd_rept, config_list)

	return True
