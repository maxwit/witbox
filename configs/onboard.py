#!/usr/bin/python

import os
import platform

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
#password maxwitcsg134
#auth login
#
#account default: qq
	fd.write('defaults\n\n')
	fd.write('account %s\n' % domain)
	fd.write('host smtp.%s\n' % domain)
	fd.write('user %s\n' % mail)
	#fd.write('from "%s" <%s>\n' % (user, mail))
	fd.write('from %s\n' % mail)
	fd.write('password %s\n' % config['mail.pass'])
	fd.write('auth login\n\n')
	fd.write('account default: %s' % domain)
	fd.close()
	os.chmod(os.getenv('HOME') + '/.msmtprc', 0600)

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
	fd.write("set pop_pass = %s\n" % config['mail.pass'])
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

	fd_rc = open('app/mail/muttrc.common')
	for line in fd_rc:
		fd.write(line)

	fd_rc.close()

	fd.close()

	kver = os.uname()[2]
	os.system('sudo apt-get install -y linux-headers-' + kver)

msmtp_config = {}

def do_report(task, fd, config_list):
	if task == 'help':
		print 'usage:\n' \
			'./powertool -r install: Report System Installation\n' \
			'./powertool -r command: Report Linux Commands Practice\n'
		fd.close()
		exit()

	print 'checking %s ...' % task
	count = 1

	### check install ###
	if task == 'install':
		fd.write("*")
	fd.write("Step %d: Installation\n" % (count))
	count += 1

	fd.write('[Partition and File System Information]:\n')
	fd_chk = open('/proc/mounts')
	for line in fd_chk:
		fd.write(line)
	fd.write('\n')

	fd.write('[Packages Installation]:\n')
	for line in os.popen("dpkg -l vim vim-gnome gcc g++ msmtp mutt"):
		fd.write(line)
	fd.write('\n')

	### check commands ###
	if task == 'command':
		fd.write("*")
	fd.write("Step %d: Unix/Linux Commands\n" % (count))
	count += 1

	fd_hist = open(os.getenv('HOME') + '/.bash_history')
	lines = fd_hist.readlines()
	start = 0
	if len(lines) > 100:
		start = len(lines) - 100
	n = start
	while n < len(lines):
		fd.write("(%d): %s" % (n - start + 1, lines[n]))
		n += 1
	fd_hist.close()

	#fd.write('Mail setting report:\n\n')
	#fd.flush()
	#os.system("dpkg -l msmtp mutt >> %s" % fn)
	#fd.write('\n')
	#fd = open(os.getenv('HOME') + '/.msmtprc')
	#for line in fd:
	#	if line != '\n' and line.strip().startswith('#') == False:
	#		task_value = line.strip().split(' ', 1)
	#		if len(task_value) == 2:
	#			msmtp_config[task_value[0].strip()] = task_value[1].strip()
	#fd.close()

	#if msmtp_config.has_task('host') != True:
	#	fd.write('Host is not configured in file msmtprc!\n')
	#elif msmtp_config['host'] != 'smtp.qq.com':
	#	fd.write('Expected host is smtp.qq.com, yours is %s\n' % msmtp_config['host'])
	#else:
	#	fd.write('Host is configured correctly!\n')

	#if msmtp_config.has_task('user') != True:
	#	fd.write('User is not configured in file msmtprc\n')
	#elif msmtp_config['user'] != config_list['user.mail']:
	#	fd.write('Expected user is %s, yours is %s\n' % (config_list['user.mail'], msmtp_config['user']))
	#else:
	#	fd.write('User is configured correctly!\n')

	#if msmtp_config.has_task('from') != True:
	#	fd.write('From is not configured in file msmtprc\n')
	#elif msmtp_config['from'] != config_list['user.mail']:
	#	fd.write('Expected from is %s, yours is %s\n' % (config_list['user.mail'], msmtp_config['from']))
	#else:
	#	fd.write('From is configured correctly!\n')

	fd.write('\n')
	os.chmod(os.getenv('HOME') + '/.muttrc', 0600)
