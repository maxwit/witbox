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
#set pop_user=jet.li@maxwit.com
#set pop_pass="???"
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
	fd.write("set pop_delete = yes\n")
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

def check_env(mail_info, conf_list):
	fd_rept = mail_info[0]
	fd_rept.write('########################################\n')
	fd_rept.write('\tPartition and File System\n')
	fd_rept.write('########################################\n')

	fd_chk = open('/proc/mounts')
	for line in fd_chk:
		mount = line.split(' ')
		fd_rept.write('%s %s %s\n' % (mount[0], mount[1], mount[2]))
	fd_chk.close()

	fd_rept.write('\n')

	fd_rept.write('########################################\n')
	fd_rept.write('\tDevice and Driver\n')
	fd_rept.write('########################################\n')

	for line in os.popen('lspci -v'):
		fd_rept.write(line)

	fd_rept.write('\n')

	fd_rept.write('########################################\n')
	fd_rept.write('\tNetwork Interface\n')
	fd_rept.write('########################################\n')

	for line in os.popen('iwconfig 2>&1'):
		fd_rept.write(line)
	fd_rept.write('-----------------------------------\n')
	for line in os.popen('ifconfig'):
		fd_rept.write(line)

	fd_rept.write('\n')

def check_build(mail_info, conf_list):
	fd_rept = mail_info[0]
	fd_rept.write('########################################\n')
	fd_rept.write('\tPackages Installation\n')
	fd_rept.write('########################################\n')

	pkgs = "libmad0-dev libid3tag0-dev libasound2-dev madplay mpg123"

	fd_rept.write('All the following packages should NOT be installed:\n%s\n\n' % pkgs)

	for line in os.popen("dpkg -l %s" % pkgs):
		fd_rept.write(line)
	fd_rept.write('\n')

def check_clike(mail_info, conf_list):
	fd_rept = mail_info[0]
	fd_rept.write('########################################\n')
	fd_rept.write('\tC-like Programming Laguages\n')
	fd_rept.write('########################################\n')

def report_usage():
	print 'usage:\n' \
			'./powertool -r env: Report System Environment\n' \
			'./powertool -r unix: Report Unix/Linux System Operation\n' \
			'./powertool -r cstart : Report C-like Programming Languages\n'

def do_report(task, mail_info, config_list):
	fd_rept = mail_info[0]
	if task == 'help':
		report_usage()
		fd_rept.close()
		return False

	if task == 'env':
		check_env(mail_info, config_list)
	elif task == 'unix':
		check_build(mail_info, config_list)
	elif task == 'cstart':
		check_clike(mail_info, config_list)
	else:
		report_usage()
		fd_rept.close()
		return False

	return True
