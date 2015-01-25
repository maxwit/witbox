#!/usr/bin/python

import os

server = '192.168.5.5'
home = os.getenv('HOME')

def check_out(repo, rw):
	os.chdir(home)

	if os.path.exists(repo):
		os.chdir(repo)
		#os.system('sed -i.bk "s/git@.*:/git@192.168.3.3:/" .git/config')
		os.system('git pull')
	elif rw:
		os.system('git clone git@%s:%s.git %s' % (server, repo, repo))
	else:
		os.system('git clone git://%s/%s.git %s' % (server, repo, repo))

try:
	fd = os.popen('ssh git@' + server)
except Exception, e:
	print e
	exit()

for line in fd:
	perm = line.split()

	if (len(perm) == 2 or len(perm) == 3) and perm[0] == 'R':
		if len(perm) == 2:
			repo = perm[1]
			rw = False
		else:
			repo = perm[2]
			rw = True

		if repo.startswith('team'):
			continue

		print '[%s]' % repo
		check_out(repo, rw)
		print
	else:
		print line,

fd.close()
