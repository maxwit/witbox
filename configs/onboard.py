#!/usr/bin/python

import os
import platform

def mail_setup(config):
	home = os.getenv('HOME')
	user = config['user.name']
	mail = config['user.mail']
	domain = mail.split('@')[1]
	# host = 'smtp.' + domain

	# msmtp setup
	print 'setup msmtp for "%s" <%s> ...' % (user, mail)
	fd = open(os.getenv('HOME') + '/.msmtprc', 'w+')
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
	os.chmod(home + '/.msmtprc', 0600)

	# fetchmail setup
	print 'setup fetchmail for "%s" <%s> ...' % (user, mail)
	fd = open(os.getenv('HOME') + '/.fetchmailrc', 'w+')
	fd.write('set daemon 600\n')
	fd.write('poll pop.%s with protocol pop3\n' % domain)
	fd.write('uidl\n')
	fd.write('user "%s"\n' % mail)
	fd.write('password "%s"\n' % config['mail.pass'])
	fd.write('keep\n')
	fd.write('mda "/usr/bin/procmail -d %T"\n')
	fd.close()
	os.chmod(home + '/.fetchmailrc', 0600)

	# procmail setup
	print 'setup procmail ...'
	fd = open(os.getenv('HOME') + '/.procmailrc', 'w+')
	fd.write('MAILDIR=$HOME/Mail\n')
	fd.write('DEFAULT=$MAILDIR/Inbox/\n')
	fd.close()
	os.chmod(home + '/.procmailrc', 0600)

	# mutt setup
	print 'setup mutt for "%s" <%s> ...' % (user, mail)
	fd = open(home + '/.muttrc', 'w+')
	## pop3 setting
	#fd.write("# pop3 setting\n")
	#fd.write("set pop_user = %s\n" % mail)
	#fd.write("set pop_pass = %s\n" % config['mail.pass'])
	#fd.write("set pop_host = pops://pop.%s\n" % domain)
	#fd.write("set pop_last = yes\n")
	#fd.write("set pop_delete = yes\n")
	#fd.write("set check_new = yes\n")
	#fd.write("set timeout = 1800\n")
	#fd.write("\n")
	# smtp setting
	fd.write("# smtp setting\n")
	fd.write("set sendmail = /usr/bin/msmtp\n")
	fd.write("# set use_from = yes\n")
	fd.write("# set envelope_from = yes\n")
	fd.write("\n")

	fd.write("# general setting\n")
	fd.write("my_hdr From: %s\n" % mail)
	fd_rc = open('app/mail/muttrc.common')
	for line in fd_rc:
		fd.write(line)
	fd_rc.close()
	fd.close()

	# signature
	fd_si = open(home + '/Mail/signature', 'w+')
	fd_si.write('Regards,\n%s\n' % user)
	#fd_si.write('MaxWit Software (Shanghai) Co., Ltd.\n')
	fd_si.close()

def do_setup(distrib, version, config):
	mail_setup(config)

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
