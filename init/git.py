import os

def config(user, conf):
	git = {}
	git['color.ui'] = 'auto'
	git['user.name'] = user.fname
	git['user.email'] = user.email
	git['sendemail.smtpserver'] = '/usr/bin/msmtp'
	git['push.default'] = 'matching'

	for (key, value) in git.items():
		os.system('git config --global %s \"%s\"' % (key, value))

	return [user.home + '/.gitconfig']
