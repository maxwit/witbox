#!/usr/bin/python

import os
import zipfile

def vmx_debug(arg):
	return os.system('sudo /usr/lib/vmware/bin/vmware-vmx-debug ' + arg)

def unlock_osx():
	f = zipfile.ZipFile('unlock-all-v120.zip')
	for file in f.namelist():
		f.extract(file, '/tmp/')
		mod = f.getinfo(file).external_attr >> 16 & 0x1ff
		os.chmod('/tmp/' + file, mod)

	os.chdir('/tmp/unlock-all-v120/linux')
	os.system('sudo ./install.sh')
	f.close()

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
