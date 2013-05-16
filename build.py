#!/usr/bin/python
#
# The Main Program for Building Embedded Development Environment
#
# http://www.maxwit.com
# http://maxwit.github.com
# http://maxwit.googlecode.com
#

import os,sys,re
#import shutil
#import socket, fcntl, struct
from optparse import OptionParser
from xml.etree import ElementTree
import lsb_release

global curr_user

def traverse(node, path):
	if not os.path.exists(path):
		print "creating \"%s\"" % path
		os.mkdir(path)
	#else:
	#	print "skipping \"%s\"" % path
	lst = node.getchildren()
	for n in lst:
		traverse(n, path + '/' + n.attrib['name'])

# population the target directory
def populate_tree(fn, rm, top = ''):
	tree = ElementTree.parse(fn)
	root = tree.getroot()
	top += '/' + root.attrib['name']
	if not os.path.isdir(top):
		print "Directory " + top + " not exist!"
		exit()
	if top == '' or top == '/':
		print 'error: connot remove ' + top
		return
	os.system('sudo chown $USER ' + top) # fixme!
	if rm == True:
		os.system('sudo rm -rvf ' + top + '/*')
	traverse(root, top)

# install software
def install_config(curr_distrib, curr_version):
	upgrade  = ''
	install  = ''
	curr_arch = os.popen('uname -m').read().replace('\n','') # fixme
	#os.system(r'tools/apt_update.sh')
	tree = ElementTree.parse(r'app/apps.xml')
	root = tree.getroot()
	dist_list = root.getchildren()
	for dist_node in dist_list:
		if dist_node.attrib['name'] == curr_distrib:
			upgrade = dist_node.attrib['upgrade']
			install = dist_node.attrib['install']

			if upgrade <> '':
				os.system('sudo ' + upgrade)

			release_list = dist_node.getchildren()
			for release in release_list:
				version = release.attrib['version']
				if version == 'all' or version == curr_version:
					app_list = release.getchildren()
					for app_node in app_list:
						attr_arch = app_node.get('arch', curr_arch)
						attr_def  = app_node.get('default')
						if attr_arch == curr_arch and attr_def <> 'n':
							print 'Installing \"%s\"' % app_node.text
							os.system('sudo ' + install + ' ' +  app_node.text)
							attr_cate = app_node.get('class')
							attr_post = app_node.get('post')
							if attr_post <> None:
								os.system('cd app/' + attr_cate  + ' && ./' + attr_post) #fixme: catch exception
							print ''
					if version == curr_version:
						break
			break

# get distribution name and release version
def distrib_version():
	#fi = open('/etc/issue', 'r')
	#line = fi.readline()
	#fi.close()
	#distrib = line.split(' ')[0].lower()
	##version = line.split(' ')[1].lower()
	#distinf = lsb_release.get_distro_information()
	#version = distinf.get('CODENAME', 'n/a')
	distrib = os.popen('lsb_release -si').read().replace('\n','') # fixme
	version = os.popen('lsb_release -sc').read().replace('\n','') # fixme
	return (distrib.lower(), version)

#def config_sys():
#	fp = open('/etc/passwd', 'r')
#	for line in fp:
#		account = line.split(',')[0].split(':')
#		user_name = account[0]
#		full_name = account[4]
#		if user_name == curr_user:
#			#print user_name, full_name
#			break
#	fp.close()
#	email_name = full_name.lower().replace(' ', '.')
#	#print email_name + '@maxwit.com'
#
#	os.system('./tools/config.sh')

def id_equal(str1, str2):
	str1 = re.sub('^\s+', '', str1)
	str1 = re.sub('\s+$', '', str1)
	str1 = str1.lower()
	str2 = re.sub('^\s+', '', str2)
	str2 = re.sub('\s+$', '', str2)
	str2 = str2.lower()
	return str1 == str2

def main():
	parser = OptionParser()
	parser.add_option('-m', '--maxwit', dest='maxwit',
					  default=False, action='store_true',
					  help="MaxWit specific setting")
	parser.add_option('-i', '--init', dest='sysinit',
					  default=False, action='store_true',
					  help="disable sudo password")
	parser.add_option('-r', '--remove-top', dest='rm',
					  default=False, action='store_true',
					  help="remove top directory before populating directory tree")
	parser.add_option('-o', '--overwrite', dest='overwrite',
					  default=False, action='store_true',
					  help="overwrite system configuration file")
	parser.add_option('-s', '--sync', dest='sync',
					  default=False, action='store_true',
					  help="synchronize archives")
	parser.add_option('-v', '--version', dest='version', action='store_true',
					  default=False,
					  help="show PowerTool version")

	(options, args) = parser.parse_args()
	if args:
		parser.error("No arguments are permitted")

	if options.version:
		# fixme
		print "  MaxWit PowerTool v1.0-rc1"
		print "  http://www.maxwit.com"
		exit()

	if options.sysinit:
		os.system('cd tools && sudo ./sudo_pass.sh ' + curr_user + ' && ./desktop_layout.sh && ./init.sh')

		vendor = os.popen('sudo dmidecode -s system-manufacturer').read().replace('\n','') # fixme
		board  = os.popen('sudo dmidecode -s system-product-name').read().replace('\n','') # fixme

		run = ''
		idf = open('./platform/id_table', 'r')
		for ids in idf:
			bid = ids.replace('\n','').split(':')
			if id_equal(bid[0], vendor) and id_equal(bid[1], board):
				run = './platform/' + bid[2]
				break
		idf.close()

		if run <> '':
			os.system('test -x ' + run + ' && ' + run)

		exit()

	if options.sync:
		os.system("cd tools && ./mwsync.sh")
		exit()

	if options.rm:
		print "Warning: top dir will be removed!"

	if options.overwrite:
		print 'overwrite'

	(distrib, version) = distrib_version()
	install_config(distrib, version)

	# fixme: to be removed
	#config_sys()

	populate_tree('tree/tree.xml', options.rm)

if __name__ == "__main__":
	curr_user = os.getenv('USER')
	if curr_user == 'root':
		print 'cannot run as root!'
		exit()

	main()
