#!/usr/bin/python

import os,sys,re
from optparse import OptionParser

def split(path):
	print 'splitting %s ...' % path

	fd_src = open(path)
	fd_dst = open(path + '_split.tex', 'w+')

	for line in fd_src:
		fd_dst.write(line)

	fd_dst.close()
	fd_src.close()

if __name__ == "__split__":
	parser = OptionParser()
	parser.add_option('-f', '--file', dest='file',
					  default=False, action='store_true',
					  help="file to be splitted")

	(options, args) = parser.parse_args()

	if options.file:
		split(args[0])
		exit()

	print 'usage: ...!'
