#!/usr/bin/python

import os,sys,re
from optparse import OptionParser

def split(path):
	print 'splitting %s ...' % path

	fd_src = open(path)

	fd_ch = None
	ch = 0
	for line in fd_src:
		if re.match(r'^\\chapter{.*', line) <> None:
			if ch > 0:
				fd_ch.close()

			ch += 1
			fd_ch = open('/tmp/chapter%d.tex' % ch, 'w+')

		if fd_ch <> None:
			fd_ch.write(line)

	if fd_ch <> None:
		fd_ch.close()

	fd_src.close()

	fd_dst = open(path + '_split', 'w+')
	fd_dst.close()

if __name__ == "__main__":
	parser = OptionParser()
	parser.add_option('-f', '--file', dest='path',
					  default=False, action='store_true',
					  help="path to the file to be splitted")

	(options, args) = parser.parse_args()

	if options.path:
		split(args[0])
		exit()

	print 'usage: ...!'
