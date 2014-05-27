#!/usr/bin/python

import os

def vmx_debug(arg):
	return os.system('sudo /usr/lib/vmware/bin/vmware-vmx-debug ' + arg)

def unlock_osx():
	pass

vmx_debug('-version')

fd =  open('sn.cfg')
for line in fd:
	sn = line[:-1]
	res = vmx_debug('--new-sn ' + sn)
	if res == 0:
		print sn + ' is the valid key'
		unlock_osx()
		exit()

print 'VMWare hack failed'
