#!/usr/bin/python

import os

server = '192.168.1.1'
home = os.getenv('HOME')

def check_out(mode, repo):
	os.chdir(home)

	if os.path.exists(repo):
		os.chdir(repo)
		os.system('git pull')
	elif mode == 'W':
		os.system('git clone git@%s:%s.git %s' % (server, repo, repo))
	else:
		os.system('git clone git://%s/%s.git %s' % (server, repo, repo))

try:
	fd = os.popen('ssh git@' + server)
except Exception, e:
	print e
	exit()

for line in fd:
	repo = line.split()
	if len(repo) != 3 or repo[0] != 'R':
		continue

	print '[%s]' % repo[2]
	check_out(repo[1], repo[2])

	print

fd.close()
